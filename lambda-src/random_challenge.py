import random
import json

PHOTO_CHALLENGES = [
    "Fotografiere jemanden, der versucht, den DJ um einen Song zu bitten.",
    "Mache ein Selfie mit einem Gast, der am meisten glitzert.",
    "Fotografiere einen Gast, der so tut, als wäre er das Brautpaar.",
    "Ein Bild von einem schiefgelaufenen Gruppenfoto (extra witzig!).",
    "Mache ein Foto von den witzigsten Tanzbewegungen des Abends.",
    "Finde jemanden, der ein Dessert stibitzt, und halte es fest.",
    "Fotografiere eine Person, die ihr Getränk mit einer anderen teilt.",
    "Ein Foto von einem Kind, das versucht, den Brautstrauß zu werfen.",
    "Mache ein Selfie mit dem tollsten Bart oder der kreativsten Frisur.",
    "Fotografiere einen Gast, der sich den Bauch hält vor Lachen.",
    "Ein Foto von einer Gruppe, die gleichzeitig tanzt – aber völlig aus dem Takt!",
    "Halte den Moment fest, wenn jemand eine schlechte Karaoke-Darbietung startet.",
    "Fotografiere jemanden, der heimlich Nachschlag holt.",
    "Ein Foto von den kreativsten Schuhen auf der Tanzfläche.",
    "Finde jemanden, der die Hochzeitstorte anschaut, als wäre es das schönste Kunstwerk der Welt.",
    "Mache ein Bild von einem Gast, der eine verrückte Grimasse zieht.",
    "Fotografiere die beste High-Five des Abends.",
    "Ein Bild von einem Gast, der versucht, den Brautstrauß zu fangen – aber scheitert.",
    "Finde eine Gruppe, die ihre Drinks synchron hebt, und knipse den Moment.",
    "Ein Selfie mit der Braut, während sie tanzt.",
    "Fotografiere jemanden, der versucht, möglichst elegant einen Teller fallen zu lassen.",
    "Ein Bild von einem Gast, der im Buffet kämpferisch die besten Häppchen sichert.",
    "Finde den längsten Toast des Abends und dokumentiere ihn.",
    "Fotografiere ein Paar, das sich zufällig in der gleichen Farbe gekleidet hat.",
    "Ein Selfie mit jemandem, der sich mit einer Sonnenbrille auf der Tanzfläche versteckt.",
    "Ein Foto von einem Gast, der versucht, die Deko als Accessoire zu tragen.",
    "Mache ein Selfie mit einem Gast, der aussieht, als wäre er im falschen Film.",
    "Ein Bild von einem überraschenden Gast (z. B. ein tierischer Freund!).",
    "Fotografiere den chaotischsten Tisch nach dem Essen.",
    "Ein Bild von einem Gast, der übermäßig begeistert den Brautstrauß wirft.",
    "Mache ein Selfie mit dem Fotografen (Meta!).",
    "Fotografiere jemanden, der heimlich einen witzigen Tanzschritt übt.",
    "Ein Bild von der Tanzfläche, wenn gerade alle einen Kreis bilden.",
    "Finde einen Gast, der still und heimlich am Handy klebt, und knipse ihn.",
    "Mache ein Foto von jemandem, der sich gerade fragt, was im Cocktail drin ist.",
    "Ein Bild von einem Gast, der die Torte anschaut, als wäre sie zu schade zum Essen.",
    "Fotografiere die kreativste Getränkekombination des Abends.",
    "Mache ein Foto von einem zufällig entstandenen Partnerlook.",
    "Ein Selfie mit dem Brautpaar, während es auf der Tanzfläche ist.",
    "Ein Foto von einem Gast, der so tut, als wäre er der DJ.",
    "Finde jemanden, der eine zu große Portion Nachtisch auf dem Teller hat.",
    "Ein Foto von der witzigsten Tischunterhaltung, die du finden kannst.",
    "Fotografiere einen Gast, der versucht, einen Luftballon zu fangen.",
    "Ein Bild von einem Gast, der im Eifer des Gefechts ein Missgeschick erlebt.",
    "Mache ein Selfie mit der ältesten und der jüngsten Person auf der Feier.",
    "Fotografiere jemanden, der versucht, die Tanzfläche für sich allein zu beanspruchen.",
    "Ein Foto von einer Gruppe, die sich für ein spontanes Gruppenbild formiert.",
    "Finde jemanden, der den Toast zu ernst nimmt, und halte den Moment fest.",
    "Mache ein Selfie mit dem kreativsten Kleidungsstück des Abends.",
]


def lambda_handler(event, context):
    challenge = random.choice(PHOTO_CHALLENGES)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({"challenge": challenge}),
    }
