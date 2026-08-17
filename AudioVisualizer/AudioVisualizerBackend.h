#ifndef AUDIOVISUALIZERBACKEND_H
#define AUDIOVISUALIZERBACKEND_H

#include <QObject>
#include <QList>
#include <QThread>
#include <QMutex>
#include <QVariant>
#include "stdafx.h"

class AudioVisualizerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY_READONLY_AUTO(bool, running)
    Q_PROPERTY_AUTO(int, bandCount)
public:
    explicit AudioVisualizerBackend(QObject *parent = nullptr);
    ~AudioVisualizerBackend() override;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setBandCount(int count);

signals:
    void bandsUpdated(const QVariantList &bands);
    void errorOccurred(const QString &error);

private:
    void captureThread();
    void fft(float *data, int size);
    QVariantList computeBands(float *fftData, int fftSize, int sampleRate);

    QMutex m_mutex;
};

#endif // AUDIOVISUALIZERBACKEND_H