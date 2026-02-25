init -5 python:
    # On force le changement de langue dès le chargement du moteur
    # sans attendre que le jeu demande "quelle est la langue par défaut"
    languages = renpy.known_languages()
    if "french" in languages:
        renpy.change_language("french")

# On garde quand même celle-là au cas où
define config.default_language = "french"