#ifndef TWIKOOCOMMENTSBACKEND_H
#define TWIKOOCOMMENTSBACKEND_H

#include <QObject>
#include <QString>
#include <QList>
#include <QVariantMap>
#include <QThread>
#include "stdafx.h"

class TwikooCommentsBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY_READONLY_AUTO(bool, loading)
    Q_PROPERTY_READONLY_AUTO(bool, connected)
public:
    explicit TwikooCommentsBackend(QObject *parent = nullptr);
    ~TwikooCommentsBackend() override;

    Q_INVOKABLE void fetchComments(const QString &clusterUri, const QString &database,
                                   const QString &collection, const QString &pageId,
                                   bool tlsEnabled = false, bool allowInvalidCertificates = false);
    Q_INVOKABLE void testConnection(const QString &clusterUri, bool tlsEnabled = false,
                                    bool allowInvalidCertificates = false);

signals:
    void commentsUpdated(const QVariantList &comments);
    void fetchError(const QString &error);
    void connectionTested(bool success, const QString &message);
};

#endif // TWIKOOCOMMENTSBACKEND_H