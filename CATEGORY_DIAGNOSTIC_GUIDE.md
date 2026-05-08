# Diagnostic: Produits non visibles dans la catégorie Gadgets

## Problème
Vous avez ajouté un produit dans la catégorie "Gadgets", mais:
- Le produit n'apparaît pas quand vous cliquez sur l'icône Gadgets
- Les sous-catégories de Gadgets ne s'affichent pas

## Causes Possibles

### 1. **Produit avec categoryId incorrect**
Le produit a été créé avec un `categoryId` qui ne correspond à aucune catégorie existante.

### 2. **Catégorie Gadgets sans ID valide**
La catégorie "Gadgets" dans la base de données a un ID différent de celui utilisé lors de la création du produit.

### 3. **Sous-catégories avec parentId incorrect**
Les sous-catégories de Gadgets ont un `parentId` qui ne correspond pas à l'ID de Gadgets.

### 4. **Problème de synchronisation**
Le produit a été créé localement mais n'a pas encore été synchronisé, ou vice-versa.

## Solution: Exécuter le Diagnostic

### Étape 1: Accéder à l'écran de diagnostic
Ajoutez temporairement ce bouton quelque part dans votre app (par exemple dans le ProfileScreen):

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoryDiagnosticScreen(),
      ),
    );
  },
  child: const Text('Diagnostic Catégories'),
)
```

### Étape 2: Vérifier la structure des catégories
L'écran de diagnostic affichera:
- Toutes les catégories racine (niveau 0)
- Leurs sous-catégories (niveau 1, 2)
- Le nombre de produits dans chaque catégorie
- L'ID de chaque catégorie et le parentId des sous-catégories

### Étape 3: Vérifier les produits
L'écran affichera aussi tous les produits avec:
- Leur nom
- Leur `categoryId` (l'ID de catégorie assigné)
- Un indicateur vert si le categoryId est valide, rouge sinon

## Corrections Possibles

### Si le produit a un categoryId NULL:
Le produit n'a pas été correctement assigné à une catégorie. Vous devez:
1. Modifier le produit dans l'app
2. Sélectionner explicitement la catégorie "Gadgets" ou une de ses sous-catégories
3. Sauvegarder

### Si le produit a un categoryId qui n'existe pas:
Le produit référence une catégorie supprimée ou invalide. Même solution que ci-dessus.

### Si les sous-catégories ne s'affichent pas:
Vérifiez dans le diagnostic que:
- La catégorie "Gadgets" existe et a un ID (ex: 5)
- Les sous-catégories ont `parentId: 5` (ou l'ID de Gadgets)

### Si rien ne fonctionne:
Exécutez cette requête SQL pour voir la structure complète:

```sql
-- Voir toutes les catégories
SELECT id, name, parent_id, level FROM categories ORDER BY level, name;

-- Voir tous les produits avec leur catégorie
SELECT p.id, p.name, p.category_id, c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
ORDER BY p.id DESC
LIMIT 20;
```

## Structure Attendue

Pour que tout fonctionne correctement:

```
Catégories:
- Gadgets (id: 5, parent_id: NULL)
  - Accessoires (id: 12, parent_id: 5)
  - Électronique (id: 13, parent_id: 5)

Produits:
- Produit A (category_id: 5)        → Apparaît quand on clique sur Gadgets
- Produit B (category_id: 12)       → Apparaît quand on sélectionne "Accessoires"
- Produit C (category_id: NULL)     → N'apparaît PAS ❌
- Produit D (category_id: 999)      → N'apparaît PAS ❌ (catégorie inexistante)
```

## Comment Ajouter Correctement un Produit

1. Cliquer sur le bouton "+" pour ajouter un produit
2. Dans le formulaire, sélectionner la catégorie "Gadgets"
3. **IMPORTANT**: Vérifier que la catégorie est bien sélectionnée avant de sauvegarder
4. Sauvegarder le produit
5. Le produit devrait apparaître quand on clique sur Gadgets

## Notes Importantes

- Quand on clique sur "Gadgets", on voit **uniquement** les produits avec `category_id = ID_DE_GADGETS`
- Pour voir les produits des sous-catégories, il faut cliquer sur le chip de la sous-catégorie
- Le tri "Plus proche" nécessite l'accès à la localisation

## Prochaines Améliorations Possibles

1. **Affichage hiérarchique**: Quand on clique sur Gadgets, montrer les produits de Gadgets ET de toutes ses sous-catégories
2. **Validation**: Empêcher la création de produits sans categoryId valide
3. **Migration**: Corriger automatiquement les produits avec des categoryId invalides
