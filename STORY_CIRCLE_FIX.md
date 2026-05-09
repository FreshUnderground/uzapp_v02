# Story Circle Display Fix - Home Screen

## Problème
Sur le Home Screen, les **stories** s'affichaient en **carré dans un composant rectangle** au lieu de s'afficher en **cercles parfaits**.

## Cause Root
`CircleAvatar` avec `backgroundImage` ne garantit pas un clipping parfait de l'image. L'image peut déborder et apparaître carrée, surtout avec certaines proportions d'images.

## Solution
Remplacement de `CircleAvatar` par `ClipOval` + `Container` avec `DecorationImage` et `BoxFit.cover`.

### Fichiers modifiés

#### 1. `lib/ui/screens/story_feed_screen.dart` (Lignes 136-165)

**AVANT :**
```dart
child: CircleAvatar(
  radius: 30,
  backgroundColor: Colors.grey[200],
  backgroundImage: NetworkImage(
    firstStory.mediaUrl.isNotEmpty
        ? CryptoUtils.decrypt(firstStory.mediaUrl)
        : '',
  ),
),
```

**APRÈS :**
```dart
child: ClipOval(
  child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      image: DecorationImage(
        image: NetworkImage(
          firstStory.mediaUrl.isNotEmpty
              ? CryptoUtils.decrypt(firstStory.mediaUrl)
              : '',
        ),
        fit: BoxFit.cover,  // ← Clipping parfait !
      ),
    ),
    child: Stack(
      children: [
        if (firstStory.mediaType == 'video')
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: UzaColors.primary,
                size: 12,
              ),
            ),
          ),
      ],
    ),
  ),
),
```

#### 2. `lib/ui/components/story_circle.dart` (Lignes 59-74)

**AVANT :**
```dart
child: CircleAvatar(
  radius: 30,
  backgroundColor: Colors.grey[200],
  backgroundImage: story.mediaUrl.isNotEmpty
      ? CachedNetworkImageProvider(
          CryptoUtils.decrypt(story.mediaUrl),
        )
      : null,
  child: story.mediaUrl.isEmpty
      ? Icon(
          isVideo ? Icons.play_circle_outline : Icons.image,
          color: Colors.grey[400],
          size: 30,
        )
      : null,
),
```

**APRÈS :**
```dart
child: ClipOval(
  child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      image: story.mediaUrl.isNotEmpty
          ? DecorationImage(
              image: CachedNetworkImageProvider(
                CryptoUtils.decrypt(story.mediaUrl),
              ),
              fit: BoxFit.cover,  // ← Clipping parfait !
            )
          : null,
    ),
    child: story.mediaUrl.isEmpty
        ? Center(
            child: Icon(
              isVideo ? Icons.play_circle_outline : Icons.image,
              color: Colors.grey[400],
              size: 30,
            ),
          )
        : null,
  ),
),
```

## Pourquoi ClipOval fonctionne mieux

### CircleAvatar (Problème)
- Utilise `backgroundImage` qui peut déborder
- Ne clippe pas toujours correctement l'image
- Problèmes avec certaines proportions d'images
- L'image peut apparaître carrée aux coins

### ClipOval + Container (Solution)
- `ClipOval` force un clipping circulaire parfait
- `BoxFit.cover` assure que l'image remplit tout le cercle
- Pas de débordement possible
- Fonctionne avec toutes les proportions d'images

## Structure du cercle

```
Container (gradient border)
└── Container (white border)
    └── ClipOval (circular clip)
        └── Container (60x60)
            ├── DecorationImage (l'image de la story)
            └── Stack
                └── Positioned (indicateur vidéo si nécessaire)
```

## Résultat

✅ Les stories s'affichent maintenant en **cercles parfaits** sur le Home Screen  
✅ L'image est **clippée correctement** dans le cercle  
✅ L'indicateur vidéo (play icon) est **bien positionné**  
✅ Fonctionne avec **toutes les proportions d'images**  
✅ Pas de débordement ni d'artefacts visuels  

## Test

1. Ouvrez l'app
2. Allez sur le Home Screen
3. Regardez la section "Mes Stories"
4. ✅ Les stories doivent être dans des cercles parfaits
5. Les images ne doivent pas déborder
6. Si c'est une vidéo, l'icône play doit être visible en bas à droite

## Note

Le `_FullStoryFeed` (quand on clique pour voir toutes les stories) utilise des **cartes rectangulaires** avec `borderRadius: 16`. C'est **intentionnel** car c'est un affichage en grille, pas des cercles.

Seul le `_CompactStoryFeed` (sur le Home Screen) utilise des cercles.
