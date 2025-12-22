#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>

class Weather : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString city READ city NOTIFY changed)
    Q_PROPERTY(int temperature READ temperature NOTIFY changed)
    Q_PROPERTY(QString description READ description NOTIFY changed)
    Q_PROPERTY(QString icon READ icon NOTIFY changed)

    Q_PROPERTY(int humidity READ humidity NOTIFY changed)
    Q_PROPERTY(int pressure READ pressure NOTIFY changed)
    Q_PROPERTY(double windSpeed READ windSpeed NOTIFY changed)

    Q_PROPERTY(int aqi READ aqi NOTIFY aqiChanged)
    Q_PROPERTY(QString aqiCategory READ aqiCategory NOTIFY aqiChanged)
    Q_PROPERTY(QVariantMap pollutants READ pollutants NOTIFY aqiChanged)

    Q_PROPERTY(QVariantList forecast READ forecast NOTIFY forecastChanged)
    Q_PROPERTY(bool hasApiKey READ hasApiKey NOTIFY apiKeyChanged)

public:
    explicit Weather(QObject *parent = nullptr) : QObject(parent) {}

    // ---------- Config ----------
    void loadConfig()
    {
        QString path = QStandardPaths::writableLocation(
            QStandardPaths::AppConfigLocation);
        QDir().mkpath(path);

        QSettings s(path + "/config.ini", QSettings::IniFormat);
        m_apiKey = s.value("apiKey").toString();
        m_hasApiKey = !m_apiKey.isEmpty();

        qDebug().noquote()
        << "\n========== CONFIG =========="
        << "\nConfig path:" << path
        << "\nAPI key present:" << m_hasApiKey
        << "\n============================";

        emit apiKeyChanged();
    }

    Q_INVOKABLE void saveApiKey(const QString &key)
    {
        if (key.trimmed().isEmpty())
            return;

        QString path = QStandardPaths::writableLocation(
            QStandardPaths::AppConfigLocation);

        QSettings s(path + "/config.ini", QSettings::IniFormat);
        s.setValue("apiKey", key.trimmed());

        m_apiKey = key.trimmed();
        m_hasApiKey = true;

        qDebug() << "API key saved";

        emit apiKeyChanged();
    }

    // ---------- API ----------
    Q_INVOKABLE void fetch(const QString &cityName)
    {
        if (!m_hasApiKey) {
            qDebug() << "❌ No API key, fetch aborted";
            return;
        }

        qDebug().noquote()
        << "\n========== FETCH =========="
        << "\nCity:" << cityName
        << "\n===========================";

        QString path = QStandardPaths::writableLocation(
            QStandardPaths::AppConfigLocation);
        QDir().mkpath(path);

        QSettings s(path + "/config.ini", QSettings::IniFormat);
        s.setValue("lastCity", cityName);

        fetchCurrent(cityName);
        fetchForecast(cityName);
    }

    // ---------- Getters ----------
    QString city() const { return m_city; }
    int temperature() const { return m_temp; }
    QString description() const { return m_desc; }
    QString icon() const { return m_icon; }

    int humidity() const { return m_humidity; }
    int pressure() const { return m_pressure; }
    double windSpeed() const { return m_wind; }

    int aqi() const { return m_aqi; }
    QString aqiCategory() const { return m_aqiCategory; }
    QVariantMap pollutants() const { return m_pollutants; }

    QVariantList forecast() const { return m_forecast; }
    bool hasApiKey() const { return m_hasApiKey; }

signals:
    void changed();
    void forecastChanged();
    void aqiChanged();
    void apiKeyChanged();

private:
    QNetworkAccessManager net;

    QString m_apiKey;
    bool m_hasApiKey = false;

    QString m_city;
    int m_temp = 0;
    QString m_desc;
    QString m_icon;
    int m_humidity = 0;
    int m_pressure = 0;
    double m_wind = 0.0;

    int m_aqi = 0;
    QString m_aqiCategory;
    QVariantMap m_pollutants;

    QVariantList m_forecast;

    // ---------- Current weather ----------
    void fetchCurrent(const QString &cityName)
    {
        QUrl url(QString(
            "https://api.openweathermap.org/data/2.5/weather"
            "?q=%1&units=metric&appid=%2"
        ).arg(cityName, m_apiKey));

        auto reply = net.get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply] {
            auto json = QJsonDocument::fromJson(reply->readAll()).object();
            reply->deleteLater();

            m_city = json["name"].toString();

            auto main = json["main"].toObject();
            m_temp = qRound(main["temp"].toDouble());
            m_humidity = main["humidity"].toInt();
            m_pressure = main["pressure"].toInt();

            auto wind = json["wind"].toObject();
            m_wind = wind["speed"].toDouble();

            auto w = json["weather"].toArray().first().toObject();
            m_desc = w["description"].toString();
            m_icon = w["icon"].toString();

            qDebug().noquote()
            << "\n------ CURRENT WEATHER ------"
            << "\nCity:" << m_city
            << "\nTemp:" << m_temp << "°C"
            << "\nDesc:" << m_desc
            << "\nHumidity:" << m_humidity << "%"
            << "\nPressure:" << m_pressure << "hPa"
            << "\nWind:" << m_wind << "m/s"
            << "\nIcon:" << m_icon
            << "\n-----------------------------";

            auto coord = json["coord"].toObject();
            fetchAQI(coord["lat"].toDouble(), coord["lon"].toDouble());

            emit changed();
        });
    }

    // ---------- Forecast ----------
    void fetchForecast(const QString &cityName)
    {
        QUrl url(QString(
            "https://api.openweathermap.org/data/2.5/forecast"
            "?q=%1&units=metric&appid=%2"
        ).arg(cityName, m_apiKey));

        auto reply = net.get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply] {
            m_forecast.clear();

            auto json = QJsonDocument::fromJson(reply->readAll()).object();
            auto list = json["list"].toArray();

            for (const auto &v : list) {
                auto o = v.toObject();
                auto main = o["main"].toObject();
                auto w = o["weather"].toArray().first().toObject();

                QVariantMap e;
                e["time"] = o["dt_txt"].toString();
                e["temp"] = qRound(main["temp"].toDouble());
                e["icon"] = w["icon"].toString();
                e["desc"] = w["description"].toString();

                m_forecast.append(e);
            }

            qDebug().noquote()
            << "\n------ FORECAST ------"
            << "\nEntries:" << m_forecast.size()
            << "\n----------------------";

            emit forecastChanged();
        });
    }

    // ---------- AQI + Pollutants ----------
    void fetchAQI(double lat, double lon)
    {
        QUrl url(QString(
            "https://api.openweathermap.org/data/2.5/air_pollution"
            "?lat=%1&lon=%2&appid=%3"
        ).arg(lat).arg(lon).arg(m_apiKey));

        auto reply = net.get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply] {
            auto json = QJsonDocument::fromJson(reply->readAll()).object();
            reply->deleteLater();

            auto list = json["list"].toArray();
            if (list.isEmpty())
                return;

            auto entry = list[0].toObject();

            m_aqi = entry["main"].toObject()["aqi"].toInt();

            switch (m_aqi) {
                case 1: m_aqiCategory = "Good"; break;
                case 2: m_aqiCategory = "Fair"; break;
                case 3: m_aqiCategory = "Moderate"; break;
                case 4: m_aqiCategory = "Poor"; break;
                case 5: m_aqiCategory = "Very Poor"; break;
                default: m_aqiCategory = "Unknown";
            }

            auto c = entry["components"].toObject();
            m_pollutants.clear();

            m_pollutants["co"]    = c["co"].toDouble();
            m_pollutants["no"]    = c["no"].toDouble();
            m_pollutants["no2"]   = c["no2"].toDouble();
            m_pollutants["o3"]    = c["o3"].toDouble();
            m_pollutants["so2"]   = c["so2"].toDouble();
            m_pollutants["pm2_5"] = c["pm2_5"].toDouble();
            m_pollutants["pm10"]  = c["pm10"].toDouble();
            m_pollutants["nh3"]   = c["nh3"].toDouble();

            qDebug().noquote()
            << "\n====== AQI ======"
            << "\nIndex:" << m_aqi
            << "\nCategory:" << m_aqiCategory
            << "\nCO:" << m_pollutants["co"]
            << "\nNO:" << m_pollutants["no"]
            << "\nNO₂:" << m_pollutants["no2"]
            << "\nO₃:" << m_pollutants["o3"]
            << "\nSO₂:" << m_pollutants["so2"]
            << "\nPM2.5:" << m_pollutants["pm2_5"]
            << "\nPM10:" << m_pollutants["pm10"]
            << "\nNH₃:" << m_pollutants["nh3"]
            << "\n=================";

            emit aqiChanged();
        });
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Weather weather;
    weather.loadConfig();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Weather", &weather);
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    QString path = QStandardPaths::writableLocation(
        QStandardPaths::AppConfigLocation);
    QSettings s(path + "/config.ini", QSettings::IniFormat);
    QString lastCity = s.value("lastCity", "Delhi").toString();

    weather.fetch(lastCity);

    return app.exec();
}

#include "main.moc"
