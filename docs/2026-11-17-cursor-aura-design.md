# Cursor Aura — document de conception

2026-11-17 · Addon WoW Forever · nom **Cursor Aura** (choisi par Ghosti le 2026-11-17)

## 1. Intention

Ghosti veut que le curseur de la souris reflète son personnage : un **effet visuel animé propre à sa spé** (feu pour un Mage Feu, givre pour un Mage Givre, éclairs pour un Chaman Élémentaire, fumée pour un Voleur…). C'est un addon cosmétique, pour le plaisir et l'immersion. Il est destiné à une publication sur CurseForge.

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs**
- Un effet de particules animé qui suit le curseur. Son style dépend de la spé active ou du choix du joueur.
- 3 modes d'affichage au choix du joueur : **Aura** (par défaut), **Traînée**, **Curseur seul**.
- 2 modes de choix de l'effet : **Auto** (selon la spé, par défaut) ou **Manuel** (n'importe lequel des 13 effets).
- Quand la spé change, l'effet suit sans `/reload`.

**Non-objectifs**
- Pas de barre ni d'anneau de vie (proposé, refusé par Ghosti).
- Pas de déplacement, de blocage ni de remplacement du curseur système : c'est impossible pour un addon.
- Pas de vrais effets de sorts Blizzard (ModelScene) : trop incertain sur Forever.
- Pas encore d'effet unique par spé (39 effets) : à voir plus tard. La v1 a 13 effets « par élément ».

**Anti-objectifs** (l'addon serait raté même s'il « marche »)
- Une baisse de FPS sensible.
- Un effet qui intercepte les clics : la frame ne doit **jamais** capter la souris.
- Un effet qui gêne la lecture en combat (trop gros, trop opaque).
- Un effet qui reste figé quelque part quand le curseur disparaît (rotation de caméra au clic droit).

## 3. Contraintes

- **Client** : WoW Forever 1.60.1 (base Retail modifiée, Lua 5.1). Il n'y a que **9 classes** : Guerrier, Paladin, Chasseur, Voleur, Prêtre, Chaman, Mage, Démoniste, Druide.
- **API** : `GetCursorPosition`, `C_SpecializationInfo.GetSpecialization` / `GetSpecializationInfo` et les événements `PLAYER_SPECIALIZATION_CHANGED` / `ACTIVE_PLAYER_SPECIALIZATION_CHANGED` sont **déclarés** dans la doc d'API Forever, mais **pas vérifiés en jeu**. Prévoir un repli (voir §6).
- **Licence** : All Rights Reserved (`## Author: Ghosti`, `## X-License: All Rights Reserved` dans le `.toc`, `LICENSE.txt` EN + FR, modèle Hook & Harvest).
- **CurseForge** : nom en anglais, sans le nom du jeu ni de classe. Changelog dans chaque fichier. Captures fidèles au rendu en jeu.
- **Livraison** : comme FCB et Hook & Harvest. Version +1 à chaque livraison, zip créé avec Python `zipfile` et déposé dans `D:\World of Warcraft\_forever_\Interface\`. Ghosti installe lui-même.
- **Images** : 100 % originales, générées par code (pipeline Python, comme FCB).

## 4. Approches envisagées

| | Approche | Pour | Contre |
|---|---|---|---|
| A | Animations pré-dessinées (flipbook), une par effet | Rendu riche, très léger | Pas de vraie traînée. Chaque retouche oblige à régénérer les images. |
| **B** | **Particules en Lua** : petites textures créées, déplacées et estompées à chaque image | Fidèle aux maquettes, gère aura et traînée, ~8 petites textures, réglable en jeu | Un peu de CPU par image, à plafonner |
| C | Vrais effets de sorts (ModelScene / PlayerModel) | Rendu officiel Blizzard | Disponibilité et suivi du curseur très incertains sur Forever |

**Choix : B**, retenu par Ghosti le 2026-11-17. C'est la seule approche qui donne à la fois l'aura et la traînée, et qui reproduit les maquettes validées.

## 5. Ce qui est décidé

### 5.1 Les 13 effets
Référence visuelle : la maquette validée, `docs/maquettes/elements-v2.html` (fragment HTML, s’ouvre via le compagnon visuel ou en l’enveloppant dans une page). `spec-effects.html` et `shaman-aura.html` sont des étapes antérieures, gardées pour l’historique : en cas d’écart de couleurs, **`elements-v2.html` et le tableau ci-dessous font foi**.

| Effet | Couleurs (clair → sombre) | Comportement en aura |
|---|---|---|
| Feu | `#FFE08A` `#FF9A2E` `#E8401C` | flammèches qui montent et rétrécissent |
| Givre | `#FFFFFF` `#AEE6FF` `#3FA9F5` | flocons à 6 branches qui tournent et tombent doucement |
| Arcanes | `#FFD6FF` `#C77DFF` `#7B2CBF` | points en orbite |
| Éclairs | `#FFFFFF` `#5AB8FF` `#2F7FFF` | petits arcs électriques brisés qui crépitent depuis le centre |
| Eau | `#7FE7FF` `#4FD39A` `#2FB8C8` | onde qui s'élargit régulièrement + bulles qui montent |
| Vent | `#DDF3FF` `#7FC8FF` + rare `#FFD36A` | arcs d'air en tourbillon rapide, étincelle dorée occasionnelle |
| Nature | `#C8F57A` `#5DBB3A` `#2E7D32` | feuilles qui tournent lentement en orbite |
| Lumière | `#FFFFFF` `#FFE27A` `#F2B705` | étincelles en croix qui montent |
| Ombre | `#B58CFF` `#5A1FA8` `#2A0850` | **sinistre** : vide noir au centre, vrilles violettes aspirées en spirale, fumée noire, anneau violet qui pulse |
| Fumée | `#C9CDD4` `#8A9099` `#4A4F57` | fumée grise qui monte doucement et s'élargit (fondu normal, pas additif) |
| Gangrène | `#E6FF9A` `#7CFF2E` `#2E8B00` | flammèches vertes rapides |
| Sang | `#FF8A8A` `#D11A1A` `#6B0000` | gouttes en orbite qui se resserrent vers le centre |
| Terre | `#E8C99A` `#A9763D` `#5C3A1A` | éclats de roche carrés qui tournent en orbite |

Chaque effet a aussi un petit point central et un halo à sa couleur médiane. Ombre est l'exception : un cœur noir et un anneau violet.

### 5.2 Effet par spé (mode Auto), 9 classes Forever
| Classe | Spé → effet |
|---|---|
| Guerrier | Armes → Sang · Fureur → Feu · Protection → Terre |
| Paladin | Sacré, Protection, Vindicte → Lumière |
| Chasseur | Maîtrise des bêtes → Nature · Précision → Vent · Survie → Terre |
| Voleur | Assassinat, Hors-la-loi, Finesse → **Fumée** |
| Prêtre | Discipline, Sacré → Lumière · Ombre → Ombre |
| Chaman | Élémentaire → Éclairs · Amélioration → Vent · Restauration → Eau |
| Mage | Arcanes → Arcanes · Feu → Feu · Givre → Givre |
| Démoniste | Affliction → Ombre · Démonologie → Gangrène · Destruction → Feu |
| Druide | Équilibre → Arcanes · Farouche → Nature · Gardien → Terre · Restauration → Nature |

Ghosti a validé ce tableau (version 13 classes) le 2026-11-17. Les 4 classes absentes de Forever sont retirées. Leurs effets (Sang, Gangrène…) restent disponibles en mode Manuel.

### 5.3 Modes
- **Aura** : l'effet tourne en permanence autour du curseur, même à l'arrêt. Pas de traînée.
- **Traînée** : des particules sont émises le long du déplacement, proportionnellement à la vitesse, puis s'effacent. À l'arrêt, il ne reste que le point et le halo.
- **Curseur seul** : seulement le point central et le halo à la couleur de l'effet, sans particules.
- **Choix de l'effet** : Auto (selon la spé, tableau 5.2) ou Manuel (liste des 13).

## 6. Ce qui reste au constructeur (avec mes choix par défaut)

Ce sont des choix faits par Claude, pas par Ghosti. Ils sont modifiables.
- **Réglages** : une commande slash `/aura` qui ouvre un petit panneau maison (mode, Auto/Manuel, liste des effets). Ce panneau évite de dépendre de l'API Settings, non vérifiée sur Forever. Sous-commandes texte : `/aura aura|trainee|seul`, `/aura auto`, `/aura <effet>`.
- **Sauvegarde** : SavedVariables **par personnage**, parce que le choix Manuel dépend du perso. Prévoir un champ de version pour les migrations futures.
- **Repli si l'API de spé est absente ou renvoie nil** : effet par défaut de la classe (Guerrier Sang, Paladin Lumière, Chasseur Nature, Voleur Fumée, Prêtre Lumière, Chaman Éclairs, Mage Arcanes, Démoniste Ombre, Druide Nature).
- **Correspondance spé → effet** : passer par le **specID** renvoyé par `GetSpecializationInfo`, pas par le nom (localisé) ni par l'index. Les specID de Forever ne sont pas confirmés : ajouter `/aura debug`, qui affiche la classe, l'index, le specID et le nom de la spé. La v1 est livrée avec les specID Retail (choix de Claude) ; si `/aura debug` montre d’autres valeurs, la table est corrigée à la livraison suivante. La liste des 9 classes vient de la note vault [[Addon WoW - Forever Cast Bars]] (Forever = 9 classes refondues).
- **Rendu** : une seule frame, `EnableMouse(false)`, strata `TOOLTIP`, attachée à `UIParent`. Position = `GetCursorPosition() / UIParent:GetEffectiveScale()`, mise à jour dans `OnUpdate`. Un pool de textures réutilisées, sans `CreateTexture` à chaque image. Un plafond global d'environ 120 particules actives. Fondu `ADD` pour tous les effets sauf Ombre (fumée noire) et Fumée, en `BLEND`.
- **Éclairs** : segments `Line` (`CreateLine`) s'ils existent sur Forever, sinon sprites d'éclair pré-dessinés.
- **Masquage** : cacher l'effet pendant `IsMouselooking()` (rotation de caméra), sur les écrans de chargement et quand l'interface est masquée (Alt+Z).
- **Taille** : rayon d'aura d'environ 20–30 px à l'échelle 1, comme dans les maquettes. Pas de réglage de taille en v1, Ghosti ne l'a pas demandé.
- **Textures** : environ 8 sprites (point doux, flamme, flocon, étoile en croix, feuille, éclat de roche, bulle, bouffée de fumée), générés en blanc ou niveaux de gris par un script Python. La couleur est appliquée en jeu avec `SetVertexColor`.
- **Tests** : comme FCB, des tests LuaJIT hors jeu avec un mock de l'API. À couvrir : correspondance spé → effet, repli, migrations des SavedVariables, plafond de particules. Le rendu se vérifie en jeu par Ghosti.
- **Emplacement** : `C:\Users\klass\Projets\CursorAura\`. Addon dans `CursorAura/`, pipeline images dans `pipeline/`, tests dans `test/`, zips dans `dist/`.

## 7. Vérification en jeu (premier essai, Ghosti)
1. `/aura debug` : la spé et le specID s'affichent-ils correctement ?
2. Changer de spé : l'effet change-t-il sans `/reload` ?
3. Clics, ciblage, glisser-déposer : rien n'est bloqué ?
4. Rotation de caméra au clic droit : l'effet disparaît-il puis revient-il ?
5. FPS avant et après activation, en ville chargée : écart négligeable ?

## 8. Points ouverts
- **Nom** : « Cursor Aura » choisi. Dossier `CursorAura`, SavedVariables `CursorAuraCharDB`. Vérifier qu'il est libre sur CurseForge avant la première publication.
- Effets uniques par spé (39) : plus tard, sur demande.
