# Démo `pdo_sqlite`, travailler avec une base de données SQLite avec PHP

Une démo et de la documentation pour bien démarrer avec les bases de données SQLite et PHP.

- [Démo `pdo_sqlite`, travailler avec une base de données SQLite avec PHP](#démo-pdo_sqlite-travailler-avec-une-base-de-données-sqlite-avec-php)
  - [Installations](#installations)
  - [SQLite, quelques bases](#sqlite-quelques-bases)
    - [Le client sqlite3](#le-client-sqlite3)
    - [Démarrer](#démarrer)
    - [Persister une base de données](#persister-une-base-de-données)
    - [Gestion des bases de données](#gestion-des-bases-de-données)
  - [Changer le format de sortie, les *modes* d'affichage de SQLite](#changer-le-format-de-sortie-les-modes-daffichage-de-sqlite)
  - [Rediriger la sortie et écrire le résultat d'une requête dans un fichier](#rediriger-la-sortie-et-écrire-le-résultat-dune-requête-dans-un-fichier)
  - [Rediriger l'entrée ou charger des scripts SQL en *batch mode*](#rediriger-lentrée-ou-charger-des-scripts-sql-en-batch-mode)
  - [Travailler avec une base de données SQLite dans un projet PHP](#travailler-avec-une-base-de-données-sqlite-dans-un-projet-php)
  - [Références](#références)
    - [SQLite](#sqlite)
    - [PHP et SQLite](#php-et-sqlite)


## Installations

- [Installer SQLite](https://www.sqlite.org/download.html)
- [Installer l'extension `PDO`](https://www.php.net/manual/fr/pdo.installation.php)
- Installer l'extension [`php_pdo_sqlite`](https://www.php.net/manual/en/ref.pdo-sqlite.php)

~~~bash
#Vérifier l'installation et l'activation des extensions PDO et pdo_sqlite
php -m | grep "pdo_sqlite
PDO"
PDO
pdo_sqlite
~~~

## SQLite, quelques bases

### Le client sqlite3

sqlite3 est une interface en ligne de commande pour manipuler les bases de données relationnelle SQLite version 3. Une base de données SQLite est un simple fichier sur le disque ou peut être hébergée directement en mémoire.

~~~bash
#Le manuel de sqlite3
man sqlite3
#Afficher la version installée
sqlite3 -version
#Obtenir de l'aide les options de sqlite3
sqlite3 -help
#Executer un fichier à l'ouverture de l'interpréteur de commandes
sqlite3 -init ddl.sql
~~~

Dans l'interpréteur

~~~bash
#Afficher l'aide
sqlite>.help
#Fermer la connexion et quitter
sqlite>.exit
#Afficher les bases de données attachées (aucun à l'ouverture par défaut)
sqlite>.databases
#Afficher les tables de la base de données attachée
sqlite>.tables
#Montre les valeurs des variables d'environnement (configuration de sqlite3)
sqlite>.show
#Ouvrir une base de données persistante (fichier)
sqlite>.open db.sql3
~~~

### Démarrer

A l'ouverture, sqlite3 ouvre par défaut [une base de données en mémoire](https://www.sqlite.org/inmemorydb.html) (qui est le nom de fichier réservé `:memory`). La base de données ouverte est toujours nommée `main`. La base de données est *volatile* et toutes les transactions sur cette base seront perdues à la fermeture de la connexion. En effet, une base de données en mémoire est automatiquement détruite quand la connexion qui les a crées est close.

~~~bash
sqlite3
sqlite> CREATE TABLE IF NOT EXISTS Foo(id INT PRIMARY KEY); 
sqlite>.tables
Foo
sqlite>.exit
sqlite3
#La liste est bien vide
sqlite>.tables
~~~

Contrairement à la majorité des SGBDR, SQLite n'utilise pas l'architecture client/serveur. Une connexion à une base de données SQLite est représentée par un pointeur vers une instance d'un objet "sqlite3". Lorsque la connexion est fermée, la mémoire est libérée et les données perdues.

### Persister une base de données

~~~bash
sqlite3 mydb.sql3
#A la première requête sqlite3 va créer le fichier mydb.sql3 s'il n'existe pas
#pour persister la base
sqlite> CREATE TABLE Foo(id INT);
sqlite> .databases
sqlite> main: /path/to/mydb.sql3 r/w
#On ferme la connexion
sqlite>.exit
sqlite3 mydb.sql3
sqlite> .databases
#La transaction précédente a bien été enregistrée dans le fichier mydb.sql3
#qui persiste la base sur le disque
sqlite> main: /path/to/mydb.sql3 r/w
sqlite> .tables
sqlite>Foo
~~~

On peut voir qu'en passant un fichier en argument de sqlite3, la connexion associe le schéma principal `main` au fichier renseigné. Le fichier devient donc notre base par défaut et les transactions sont enregistrées sur le disque.

### Gestion des bases de données

En SQLite, il n'y a pas d'instruction `CREATE DATABASE`. Une connexion à une base de données SQLite peut contenir plusieurs bases de données. Une base de données est soit contenue dans un fichier, soit en mémoire. Par exemple, lorsque l'on ouvre une connexion sans indiquer de fichier, la base de données `main` pointe sur une base de données maintenue en mémoire.

On peut *attacher* et *détacher* d'autres bases de données en chargeant des fichiers avec l'instruction [`ATTACH DATABASE`](https://www.sqlite.org/lang_attach.html). Pour cela il faut indiquer le fichier à charger (qui contient la base) et le nom du schéma.

Créons une nouvelle base de données `otherdb.sql3`

~~~bash
sqlite3 otherdb.sql3
~~~

~~~bash
sqlite> CREATE TABLE Bar(id INT);
sqlite> .databases
sqlite> main: /path/to/otherdb.sql3 r/w
#On attache notre base de données précédente à la connexion sur le schéma 'mydb'
sqlite> ATTACH DATABASE 'mydb.sql3' AS mydb;
#Lister les bases de données. On voit également les droits en lecture et écriture
sqlite> .databases
main: /path/to/otherdb.sql3 r/w
mydb: /path/to/mydb.sql3 r/w
sqlite> .tables
#La table Bar sur le schéma principal (fichier otherdb.sql3) 
# et la table Foo sur le schéma 'mydb'  (fichier mydb.sql3)
Bar       mydb.Foo
#Où va être créée la table Foo ?
sqlite> CREATE TABLE Foo(id INT);
sqlite> DETACH mydb;
sqlite> INSERT INTO Foo(id) VALUES(1), (2), (3);
~~~

La commande `.databases` montre toutes les bases de données ouvertes dans la connexion. La commande `.schema` affiche le schéma complet de la base de données (i.e l'ensemble des instructions SQL la définissant). La commande `.schema`, comme la commande `.tables`, affiche le schéma de toutes les bases de données attachées. On peut détacher une base avec [DETACH](https://www.sqlite.org/lang_detach.html).

## Changer le format de sortie, les *modes* d'affichage de SQLite

sqlite3 peut montrer les résultats d'une requête dans 14 formats différents par défaut : ascii, box, csv, column, **list** (par défaut), markdown, quote, json, html, etc.

~~~bash
#Afficher le mode courant (format de sortie)
sqlite> .mode
current output mode: list
sqlite> SELECT * FROM Foo;
1
2
3
sqlite> .mode html
sqlite> SELECT * FROM Foo;
<TR><TD>1</TD>
</TR>
<TR><TD>2</TD>
</TR>
<TR><TD>3</TD>
</TR>
sqlite> .mode column
id
--
1 
2 
3 
sqlite> .mode box --wrap 30
sqlite> SELECT * FROM Foo;
┌────┐
│ id │
├────┤
│ 1  │
│ 2  │
│ 3  │
└────┘
~~~

> Il existe beaucoup d'options possibles. En savoir plus avec la commande `.help .mode`.

## Rediriger la sortie et écrire le résultat d'une requête dans un fichier

Par défaut, sqlite3 retourne les résultats d'une requête sur la sortie standard. On peut rediriger la sortie facilement avec la commande `.output` et `.once`. 

~~~bash
sqlite> .mode markdown
sqlite> .output foo.md
sqlite> SELECT * FROM Foo;
sqlite> .exit
$ cat foo.md
| id |
|----|
| 1  |
| 2  |
| 3  |
~~~

On peut même utiliser le pipe directement depuis sqlite3 pour injecter le résultat d'une requête vers un autre processus !

~~~bash
#La commande .once redirige la sortie que pour la commande suivante
sqlite> .once | grep 2
sqlite> SELECT * FROM Foo;
sqlite> SELECT * FROM Foo;
1
2
3
~~~

## Rediriger l'entrée ou charger des scripts SQL en *batch mode*

Par défaut, sqlite3 lit les requêtes SQL depuis l'entrée standard. On peut également charger un fichier contenant des requêtes SQL (*batch mode*) avec la commande `.read`

~~~bash
#Charger le script ddl.sql (batch mode)
sqlite> .read ddl.sql
sqlite> .tables
Bar Baz Foo
# Afficher le schema de la table Bar
sqlite> .schema Bar
CREATE TABLE Bar(id INT PRIMARY KEY, idFoo INT, FOREIGN KEY(idFoo) REFERENCES Foo(id));
~~~

## Travailler avec une base de données SQLite dans un projet PHP

SQLite, comme tous les autres SGBDR, peut être manipulée par un programme PHP via [l'interface PDO (PHP Data Objects)](https://www.php.net/manual/fr/intro.pdo.php). L'implémentation de PDO pour SQLite (le *driver*) est le module php `pdo_sqlite`, installé par défaut. Une fois une connexion ouverte, le code PHP pour dialoguer avec SQLite est donc le même qu'avec n'importe quel autre SGBDR.

~~~php
//Ouvrir la base de données stockée dans le fichier db.sql3 dans le repertoire courant
$dsn = 'sqlite:db.sql3';
$pdo = new PDO($dsn);
//Un prepared statement PDO
$ps = $pdo->prepare('CREATE Table Foo(id INT PRIMARY KEY);', array());
//Execution de la requête
$result = $ps->execute();
~~~

## Références

### SQLite

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Command Line Shell For SQLite : Getting Started](https://www.sqlite.org/cli.html#dschema)
- [Alphabetical List Of Documents SQLite](https://www.sqlite.org/doclist.html), articles de la doc officielle sur sqlite3 et sur ses instructions

### PHP et SQLite

- [Fonctions SQLite (PDO_SQLITE)](https://www.php.net/manual/fr/ref.pdo-sqlite.php)
- [PHP PDO](https://www.php.net/manual/fr/book.pdo.php)
