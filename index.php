<?php
/**
 * Une démonstration de manipulation de base de données SQLite avec PHP
 */

$dsn = 'sqlite:db.sq3';

$pdo = new PDO($dsn);

$ps = $pdo->prepare('CREATE Table Foo(id INT PRIMARY KEY);', array());

$result = $ps->execute();