#include "TypingFollowerBackend.h"

TypingFollowerBackend::TypingFollowerBackend(QObject *parent)
    : QObject(parent)
    , m_message("Hello from Backend")
    , m_counter(0)
{
}

QString TypingFollowerBackend::message() const
{
    return m_message;
}

void TypingFollowerBackend::setMessage(const QString &newMessage)
{
    if (m_message != newMessage) {
        m_message = newMessage;
        emit messageChanged();
    }
}

int TypingFollowerBackend::counter() const
{
    return m_counter;
}

QString TypingFollowerBackend::sayHello(const QString &name)
{
    QString greeting = QString("Hello2, %1!").arg(name);
    emit helloSaid(greeting);
    return greeting;
}

void TypingFollowerBackend::incrementCounter()
{
    m_counter++;
    emit counterChanged();
}

int TypingFollowerBackend::addNumbers(int a, int b)
{
    return a + b;
}