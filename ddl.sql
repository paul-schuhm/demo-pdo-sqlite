-- La table Foo dans notre exemple a été crée via l'entrée standard avec sqlite3
CREATE Table IF NOT EXISTS Bar(
    id INT PRIMARY KEY,
    idFoo INT,
    FOREIGN KEY(idFoo) REFERENCES Foo(id)
);

CREATE Table IF NOT EXISTS Baz(
    id INT PRIMARY KEY,
    idBar INT,
    FOREIGN KEY (idBar) REFERENCES Bar(id)
);