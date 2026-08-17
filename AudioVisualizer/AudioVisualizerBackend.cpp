#define _USE_MATH_DEFINES
#include "AudioVisualizerBackend.h"

#include <QDebug>
#include <QDateTime>
#include <QVariant>

#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <cmath>
#include <cstring>

AudioVisualizerBackend::AudioVisualizerBackend(QObject *parent)
    : QObject(parent)
{
}

AudioVisualizerBackend::~AudioVisualizerBackend()
{
    stop();
}

void AudioVisualizerBackend::start()
{
    if (_running) return;
    _running = true;
    running(true);

    QThread *workerThread = QThread::create([this]() { captureThread(); });
    connect(workerThread, &QThread::finished, workerThread, &QThread::deleteLater);
    workerThread->start();
}

void AudioVisualizerBackend::stop()
{
    if (!_running) return;
    _running = false;
    running(false);
}

void AudioVisualizerBackend::setBandCount(int count)
{
    int clamped = qBound(4, count, 64);
    if (_bandCount == clamped) return;
    bandCount(clamped);
}

void AudioVisualizerBackend::captureThread()
{
    HRESULT hr;
    IMMDeviceEnumerator *pEnumerator = nullptr;
    IMMDevice *pDevice = nullptr;
    IAudioClient *pAudioClient = nullptr;
    IAudioCaptureClient *pCaptureClient = nullptr;

    CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                          __uuidof(IMMDeviceEnumerator), (void **)&pEnumerator);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to create device enumerator"));
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    hr = pEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &pDevice);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to get default audio device"));
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    hr = pDevice->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, (void **)&pAudioClient);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to activate audio client"));
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    WAVEFORMATEX *pFormat = nullptr;
    hr = pAudioClient->GetMixFormat(&pFormat);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to get mix format"));
        pAudioClient->Release();
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    const int fftSize = 2048;
    REFERENCE_TIME hnsRequestedDuration = 10000000;

    hr = pAudioClient->Initialize(
        AUDCLNT_SHAREMODE_SHARED,
        AUDCLNT_STREAMFLAGS_LOOPBACK,
        hnsRequestedDuration,
        0,
        pFormat,
        nullptr);

    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to initialize audio client (loopback)"));
        CoTaskMemFree(pFormat);
        pAudioClient->Release();
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    UINT32 bufferFrameCount = 0;
    hr = pAudioClient->GetBufferSize(&bufferFrameCount);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to get buffer size"));
        CoTaskMemFree(pFormat);
        pAudioClient->Release();
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    hr = pAudioClient->GetService(__uuidof(IAudioCaptureClient), (void **)&pCaptureClient);
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to get capture service"));
        CoTaskMemFree(pFormat);
        pAudioClient->Release();
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    hr = pAudioClient->Start();
    if (FAILED(hr)) {
        Q_EMIT errorOccurred(tr("Failed to start audio client"));
        pCaptureClient->Release();
        CoTaskMemFree(pFormat);
        pAudioClient->Release();
        pDevice->Release();
        pEnumerator->Release();
        _running = false;
        running(false);
        CoUninitialize();
        return;
    }

    qDebug() << "AudioVisualizer: loopback capture started, sample rate:" << pFormat->nSamplesPerSec
             << "channels:" << pFormat->nChannels;

    const int bufferFrames = fftSize;
    float *audioBuffer = new float[bufferFrames * pFormat->nChannels];
    float *fftBuffer = new float[fftSize];
    int bufferPos = 0;
    int sampleRate = pFormat->nSamplesPerSec;
    int nChannels = pFormat->nChannels;

    LARGE_INTEGER hnsTimeout;
    hnsTimeout.QuadPart = 1000000;

    while (_running) {
        Sleep(15);

        UINT32 packetLength = 0;
        hr = pCaptureClient->GetNextPacketSize(&packetLength);
        if (FAILED(hr)) break;

        while (packetLength != 0 && _running) {
            BYTE *pData = nullptr;
            UINT32 numFramesAvailable = 0;
            DWORD flags = 0;

            hr = pCaptureClient->GetBuffer(
                &pData,
                &numFramesAvailable,
                &flags,
                nullptr,
                nullptr);

            if (FAILED(hr)) break;

            bool isSilent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0;

            if (numFramesAvailable > 0 && !isSilent) {
                float *pFloatData = reinterpret_cast<float *>(pData);
                for (UINT32 i = 0; i < numFramesAvailable && bufferPos < bufferFrames; i++) {
                    float sum = 0.0f;
                    for (int ch = 0; ch < nChannels; ch++) {
                        sum += pFloatData[i * nChannels + ch];
                    }
                    float mono = sum / nChannels;
                    audioBuffer[bufferPos] = mono;
                    bufferPos++;
                }
            } else {
                for (UINT32 i = 0; i < numFramesAvailable && bufferPos < bufferFrames; i++) {
                    audioBuffer[bufferPos] = 0.0f;
                    bufferPos++;
                }
            }

            hr = pCaptureClient->ReleaseBuffer(numFramesAvailable);
            if (FAILED(hr)) break;

            hr = pCaptureClient->GetNextPacketSize(&packetLength);
            if (FAILED(hr)) break;

            if (bufferPos >= bufferFrames) {
                memcpy(fftBuffer, audioBuffer, fftSize * sizeof(float));
                bufferPos = 0;

                fft(fftBuffer, fftSize);

                QVariantList bands = computeBands(fftBuffer, fftSize, sampleRate);
                QMetaObject::invokeMethod(this, [this, bands]() {
                    if (_running) {
                        Q_EMIT bandsUpdated(bands);
                    }
                }, Qt::QueuedConnection);
            }
        }
    }

    pAudioClient->Stop();
    pCaptureClient->Release();
    CoTaskMemFree(pFormat);
    pAudioClient->Release();
    pDevice->Release();
    pEnumerator->Release();

    delete[] audioBuffer;
    delete[] fftBuffer;

    qDebug() << "AudioVisualizer: capture stopped";

    CoUninitialize();
}

void AudioVisualizerBackend::fft(float *data, int size)
{
    if (size <= 1) return;

    int j = 0;
    for (int i = 1; i < size; i++) {
        int bit = size >> 1;
        while (j & bit) {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if (i < j) {
            float temp = data[i];
            data[i] = data[j];
            data[j] = temp;
        }
    }

    for (int len = 2; len <= size; len <<= 1) {
        float ang = 2.0f * (float)M_PI / (float)len;
        float wlenReal = cosf(ang);
        float wlenImag = sinf(ang);

        for (int i = 0; i < size; i += len) {
            float wReal = 1.0f;
            float wImag = 0.0f;

            for (int k = 0; k < len / 2; k++) {
                float uReal = wReal;
                float uImag = wImag;

                float tReal = data[i + k];
                float tImag = data[i + k + len / 2];

                data[i + k] = tReal + tImag;
                data[i + k + len / 2] = (tReal - tImag) * uReal - (tReal + tImag) * uImag;

                float newWReal = wReal * wlenReal - wImag * wlenImag;
                wImag = wReal * wlenImag + wImag * wlenReal;
                wReal = newWReal;
            }
        }
    }
}

QVariantList AudioVisualizerBackend::computeBands(float *fftData, int fftSize, int sampleRate)
{
    QVariantList bands;
    int numBands = _bandCount;
    int halfSize = fftSize / 2;

    float *magnitudes = new float[halfSize];
    for (int i = 0; i < halfSize; i++) {
        magnitudes[i] = sqrtf(fftData[i] * fftData[i] + fftData[i + halfSize] * fftData[i + halfSize]);
    }

    float maxMag = 0.0001f;
    for (int i = 0; i < halfSize; i++) {
        if (magnitudes[i] > maxMag) maxMag = magnitudes[i];
    }

    float minFreq = 20.0f;
    float maxFreq = (float)sampleRate / 2.0f;

    for (int b = 0; b < numBands; b++) {
        float t0 = (float)b / numBands;
        float t1 = (float)(b + 1) / numBands;

        float f0 = minFreq * powf(maxFreq / minFreq, t0);
        float f1 = minFreq * powf(maxFreq / minFreq, t1);

        int bin0 = qMax(0, (int)(f0 * fftSize / sampleRate));
        int bin1 = qMin(halfSize - 1, (int)(f1 * fftSize / sampleRate));

        float bandSum = 0.0f;
        int binCount = 0;
        for (int i = bin0; i <= bin1; i++) {
            bandSum += magnitudes[i];
            binCount++;
        }

        float avg = binCount > 0 ? bandSum / binCount : 0.0f;
        float normalized = qMin(1.0f, avg / maxMag);
        float smoothed = powf(normalized, 0.6f);
        bands.append(smoothed);
    }

    delete[] magnitudes;
    return bands;
}