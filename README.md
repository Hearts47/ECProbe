# ECProbe

Un outil d'exploration pour les créateurs d'addons **Azeroth Survivors** : il permet de « sonder » le jeu pour découvrir quelles fonctions, tables et éléments d'interface il met à disposition des addons.

> Projet de fan, non officiel. Il n'est affilié ni à Blizzard Entertainment ni aux créateurs d'Azeroth Survivors.

ECProbe a servi à trouver les données utilisées par EnemyCounter et RunPace (notamment la table `AZS_RUN`).

## Commandes

Les résultats s'affichent dans une fenêtre déplaçable et scrollable. Clique dans le texte, puis **Ctrl+A** et **Ctrl+C** pour tout copier.

| Commande | Rôle |
|---|---|
| `/ecprobe mot` | Liste les noms globaux (fonctions, tables, textes...) qui contiennent le mot. Ex : `/ecprobe azs` |
| `/ecdump nom` | Affiche le contenu d'une table globale (3 niveaux de profondeur, 800 lignes max). Ex : `/ecdump AZS_RUN` |
| `/ecdump AZS_GetXxx` | Appelle sans argument une fonction `AZS_Get*`, `AZS_Is*` ou `AZS_Gear` et affiche ce qu'elle renvoie |
| `/ecframe nom` | Décrit un cadre d'interface : taille, parent, ancres, enfants, textes. Ex : `/ecframe BenillaOptionsFrame` |

Par prudence, `/ecdump` n'appelle que les fonctions `AZS_Get*`, `AZS_Is*` et `AZS_Gear`, pour ne rien déclencher d'involontaire dans le jeu.

Chaque résultat est aussi enregistré dans la variable sauvegardée `ECProbeDB` (écrite à la fermeture du jeu).

## Installation

1. Télécharge le dossier `ECProbe` de ce dépôt (ou la dernière *release*).
2. Dans le jeu, ouvre **Options → AddOns → Ouvrir le dossier AddOns**.
3. Place le dossier `ECProbe` dedans (le dossier doit s'appeler exactement `ECProbe`).
4. Relance le jeu. Les commandes ne marchent qu'en partie.

## Licence

[MIT](LICENSE)
