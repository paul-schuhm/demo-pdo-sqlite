-- La table Foo dans notre exemple est crée en mémoire via le programme sqlite3
CREATE Table IF NOT EXISTS Bar(id INT PRIMARY KEY, idFoo INT REFERENCES Foo.id); 
CREATE Table IF NOT EXISTS Baz(id INT PRIMARY KEY, idBar INT REFERENCES Bar.id); 