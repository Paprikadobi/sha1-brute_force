Lámání heše SHA1

Instalace potřebných modulů:
    pip install -r requirements.txt

Spuštění:
    Program funguje ve dvou režimech:
    1) pro generování hešů: python main.py --hash
    2) pro lámání heše: python main.py
    
    Při lámání je možno přidat argumenty pro nastavení minimální a maximální délky testovaných hesel (--min a --max)
    a pro nastavení počtu vláken, ve kterých program poběží (--threads).

Příklady:
    Časy byly testovány na Macbook air(early 2015) při použití 4 vláken.
    heslo: abcdef (heš: 1f8ac10f23c5b5bc1167bda84b833e5c057a77d2) - čas: 355s
    heslo: Test2 (heš: 2b84f621c0fd4ba8bd514c5c43ab9a897c8c014e) - čas: 204s
