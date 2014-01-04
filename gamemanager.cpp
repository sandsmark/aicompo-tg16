#include "gamemanager.h"

#include "tile.h"
#include "map.h"
#include "player.h"
#include "bomb.h"

#include <QDebug>
#include <QFile>
#include <QQmlContext>
#include <QQuickView>
#include <QQuickItem>
#include <QPoint>
#include <QList>
#include <QQmlComponent>

GameManager::GameManager(QQuickView *view) : QObject(view),
    m_map(0), m_view(view), m_bombComponent(0)
{
    loadMap(":/maps/default.map");

    if (!m_map) {
        qWarning() << "GameManager: Unable to load default map!";
        return;
    }

    // Set up players
    const QList<QPoint> startingPositions = m_map->startingPositions();
    for (int i=0; i < startingPositions.size(); i++) {
        m_players.append(new Player(this, i));
        player(i)->setPosition(startingPositions[i]);
    }

    // Expose player objects to the QML
    m_view->rootContext()->setContextProperty("players", QVariant::fromValue(m_players));

    connect(this, SIGNAL(gameOver()), SLOT(gameEnd()));
}


void GameManager::loadMap(const QString &path)
{
    Map *map = new Map(this, path);

    if (!map->isValid()) {
        qWarning() << "Map: Parsed map isn't expected size";
        delete map;
        return;
    }

    m_view->rootContext()->setContextProperty("map", map);

    if (m_map)
        m_map->deleteLater();

    m_map = map;
}

void GameManager::userMove(const QString &direction)
{
    if (!m_map) return;

    Player *player = qobject_cast<Player*>(m_players[0]);

    QPoint position = player->position();

    if (direction == "up") {
        position.setY(position.y() - 1);
    } else if (direction == "down") {
        position.setY(position.y() + 1);
    } else if (direction == "left") {
        position.setX(position.x() - 1);
    } else if (direction == "right") {
        position.setX(position.x() + 1);
    } else if (direction == "dropBomb") {
        addBomb(position);
        return;
    } else {
        return;
    }

    if (m_map->isValidPosition(position)) {
        player->setPosition(position);
    }
}

void GameManager::addBomb(const QPoint &position)
{
    if (!m_bombComponent) {
        m_bombComponent = new QQmlComponent(m_view->engine(), QUrl("qrc:/qml/bomb/BombSprite.qml"), QQmlComponent::PreferSynchronous);
    }

    if (m_bombComponent->status() != QQmlComponent::Ready) {
        qWarning() << "GameManager: Unable to instantiate bomb sprite:" << m_bombComponent->errorString();;
        return;
    }
    QObject *playingFieldObject = m_view->rootObject()->findChild<QObject*>("playingField");
    if (!playingFieldObject) {
        qWarning() << "GameManager: Unable to locate playing field object!";
        return;
    }
    QQuickItem *playingField = qobject_cast<QQuickItem*>(playingFieldObject);
    if (!playingField) {
        qWarning() << "GameManager: Unable to locate playing field QML item!";
        return;
    }

    QQuickItem *bombSprite = qobject_cast<QQuickItem*>(m_bombComponent->create());
    bombSprite->setParentItem(playingField);

    Bomb *bomb = new Bomb(this, position, bombSprite);
    connect(bomb, SIGNAL(boom(QPoint)), m_map, SLOT(detonateBomb(QPoint)));
    bombSprite->setProperty("bombData", QVariant::fromValue(bomb));
}

void GameManager::explosionAt(const QPoint &position)
{
    int dead = 0;
    foreach(QObject *obj, m_players) {
        Player *player = qobject_cast<Player*>(obj);
        if (player->position() == position) {
            player->die();
            dead++;
        }
    }

    if (dead == m_players.size() - 1) {
        emit gameOver();
    }
}

void GameManager::gameEnd()
{
    disconnect(m_map, SIGNAL(explosionAt(QPoint)), this, SLOT(explosionAt(QPoint)));
    disconnect(m_view->rootObject(), SIGNAL(userMove(QString)), this, SLOT(userMove(QString)));

    QQuickItem *endScreen = qobject_cast<QQuickItem*>(m_view->rootObject()->findChild<QObject*>("endScreen"));
    if (endScreen) {
        endScreen->setProperty("opacity", 1.0);
    }
}

void GameManager::gameStart()
{
    connect(m_map, SIGNAL(explosionAt(QPoint)), SLOT(explosionAt(QPoint)));
    connect(m_view->rootObject(), SIGNAL(userMove(QString)), SLOT(userMove(QString)));
}

Player *GameManager::player(int id)
{
    if (id > m_players.size()) return NULL;
    return qobject_cast<Player*>(m_players[id]);
}
