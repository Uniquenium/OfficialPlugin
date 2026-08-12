#ifndef TYPINGFOLLOWERBACKEND_H
#define TYPINGFOLLOWERBACKEND_H

#include <QObject>

class TypingFollowerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString message READ message WRITE setMessage NOTIFY messageChanged)
    Q_PROPERTY(int counter READ counter NOTIFY counterChanged)

public:
    explicit TypingFollowerBackend(QObject *parent = nullptr);

    QString message() const;
    void setMessage(const QString &newMessage);

    int counter() const;

    Q_INVOKABLE QString sayHello(const QString &name);
    Q_INVOKABLE void incrementCounter();
    Q_INVOKABLE int addNumbers(int a, int b);

signals:
    void messageChanged();
    void counterChanged();
    void helloSaid(const QString &greeting);

private:
    QString m_message;
    int m_counter;
};

#endif // TYPINGFOLLOWERBACKEND_H
