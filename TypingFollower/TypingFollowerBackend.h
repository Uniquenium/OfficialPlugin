#ifndef TYPINGFOLLOWERBACKEND_H
#define TYPINGFOLLOWERBACKEND_H

#include <QObject>
#include <QString>
#include <QHash>
#include "stdafx.h"

class TypingFollowerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool listening READ listening WRITE listening NOTIFY listeningChanged)
    Q_PROPERTY(bool listenMouse READ listenMouse WRITE listenMouse NOTIFY listenMouseChanged)
public:
    explicit TypingFollowerBackend(QObject *parent = nullptr);
    ~TypingFollowerBackend() override;

    bool listening() const;
    void listening(bool v);
    bool listenMouse() const;
    void listenMouse(bool v);

    QString keyTextFromVKey(quint32 vkey) const;

    Q_INVOKABLE void clearKeys();
    Q_INVOKABLE void restartHook();

    bool hasPressedKey(quint32 vkey) const { return m_pressedKeys.contains(vkey); }
    QString pressedKeyName(quint32 vkey) const { return m_pressedKeys.value(vkey); }
    void setPressedKey(quint32 vkey, const QString &name) { m_pressedKeys[vkey] = name; }
    void removePressedKey(quint32 vkey) { m_pressedKeys.remove(vkey); }

    bool hasPressedButton(int button) const { return m_pressedMouseButtons.contains(button); }
    QString pressedButtonName(int button) const { return m_pressedMouseButtons.value(button); }
    void setPressedButton(int button, const QString &name) { m_pressedMouseButtons[button] = name; }
    void removePressedButton(int button) { m_pressedMouseButtons.remove(button); }

signals:
    void listeningChanged();
    void listenMouseChanged();
    void keyPressed(const QString &keyText);
    void keyReleased(const QString &keyText);
    void mousePressed(const QString &buttonText);
    void mouseReleased(const QString &buttonText);

private:
    void startHook();
    void stopHook();

    bool _listening = false;
    bool _listenMouse = true;
    QHash<quint32, QString> m_pressedKeys;
    QHash<int, QString> m_pressedMouseButtons;
};

#endif // TYPINGFOLLOWERBACKEND_H