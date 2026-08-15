#include "TwikooCommentsBackend.h"

#include <QDebug>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>

#include <mongocxx/client.hpp>
#include <mongocxx/uri.hpp>
#include <mongocxx/instance.hpp>
#include <mongocxx/options/find.hpp>
#include <bsoncxx/builder/stream/document.hpp>
#include <bsoncxx/json.hpp>

TwikooCommentsBackend::TwikooCommentsBackend(QObject *parent)
    : QObject(parent)
{
}

TwikooCommentsBackend::~TwikooCommentsBackend()
{
}

static QString formatTimestamp(qint64 ts)
{
    QDateTime dt = QDateTime::fromMSecsSinceEpoch(ts);
    return dt.toString(Qt::ISODate);
}

void TwikooCommentsBackend::fetchComments(const QString &clusterUri, const QString &database,
                                          const QString &collection, const QString &pageId)
{
    Q_UNUSED(pageId);

    if (clusterUri.isEmpty()) {
        Q_EMIT fetchError(tr("MongoDB cluster URI is empty"));
        return;
    }

    loading(true);

    QThread *workerThread = QThread::create([this, clusterUri, database, collection]() {
        QVariantList comments;
        QString errorMsg;

        try {
            static mongocxx::instance instance{};

            mongocxx::client client(mongocxx::uri(clusterUri.toStdString()));

            auto db = client.database(database.toStdString());
            auto coll = db.collection(collection.toStdString());

            mongocxx::options::find opts;
            opts.sort(bsoncxx::builder::stream::document{}
                      << "created" << -1
                      << bsoncxx::builder::stream::finalize);

            auto cursor = coll.find({}, opts);

            for (auto &&doc : cursor) {
                QVariantMap comment;
                QByteArray json = QByteArray::fromStdString(bsoncxx::to_json(doc));
                QJsonDocument docJson = QJsonDocument::fromJson(json);
                if (docJson.isObject()) {
                    QJsonObject obj = docJson.object();
                    comment["id"] = obj["_id"].toString();
                    comment["name"] = obj["nick"].toString();
                    comment["email"] = obj["mail"].toString();
                    comment["avatar"] = obj.contains("mailMd5")
                        ? QString("https://www.gravatar.com/avatar/%1?s=64").arg(obj["mailMd5"].toString())
                        : "";
                    comment["url"] = obj["url"].toString();
                    comment["link"] = obj["link"].toString();
                    comment["ua"] = obj["ua"].toString();
                    comment["ip"] = obj["ip"].toString();
                    comment["isSpam"] = obj["isSpam"].toBool(false);
                    comment["top"] = obj["top"].toBool(false);
                    comment["master"] = obj["master"].toBool(false);
                    comment["pid"] = obj.contains("pid") && !obj["pid"].isNull() ? obj["pid"].toString() : "";
                    comment["rid"] = obj.contains("rid") && !obj["rid"].isNull() ? obj["rid"].toString() : "";

                    if (obj.contains("created")) {
                        qint64 ts = obj["created"].toVariant().toLongLong();
                        comment["created"] = formatTimestamp(ts);
                    }

                    if (obj.contains("comment")) {
                        QString raw = obj["comment"].toString();
                        raw.replace(QRegularExpression("<img[^>]*>", QRegularExpression::CaseInsensitiveOption),
                                    tr("[image]"));
                        comment["content"] = raw;
                    }

                    comments.append(comment);
                }
            }

            qDebug() << "TwikooComments: fetched" << comments.size() << "documents from"
                     << database << "." << collection;

            QMetaObject::invokeMethod(this, [this, comments]() {
                loading(false);
                connected(true);
                Q_EMIT commentsUpdated(comments);
            }, Qt::QueuedConnection);

        } catch (const std::exception &e) {
            errorMsg = QString::fromStdString(e.what());
            qDebug() << "TwikooComments: fetch error:" << errorMsg;
            QMetaObject::invokeMethod(this, [this, errorMsg]() {
                loading(false);
                connected(false);
                Q_EMIT fetchError(errorMsg);
            }, Qt::QueuedConnection);
        }
    });

    connect(workerThread, &QThread::finished, workerThread, &QThread::deleteLater);
    workerThread->start();
}

void TwikooCommentsBackend::testConnection(const QString &clusterUri)
{
    if (clusterUri.isEmpty()) {
        Q_EMIT connectionTested(false, tr("MongoDB cluster URI is empty"));
        return;
    }

    loading(true);

    QThread *workerThread = QThread::create([this, clusterUri]() {
        bool success = false;
        QString message;

        try {
            static mongocxx::instance instance{};

            mongocxx::client client(mongocxx::uri(clusterUri.toStdString()));

            auto db = client.database("admin");
            auto result = db.run_command(bsoncxx::builder::stream::document{}
                                         << "ping" << 1
                                         << bsoncxx::builder::stream::finalize);
            success = true;
            message = tr("Connection successful");

        } catch (const std::exception &e) {
            success = false;
            message = QString::fromStdString(e.what());
        }

        QMetaObject::invokeMethod(this, [this, success, message]() {
            loading(false);
            connected(success);
            Q_EMIT connectionTested(success, message);
        }, Qt::QueuedConnection);
    });

    connect(workerThread, &QThread::finished, workerThread, &QThread::deleteLater);
    workerThread->start();
}