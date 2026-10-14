"""Crée un compte de test CognicQuest dans le projet Supabase de env.json.

CognicQuest n'a pas de rôle administrateur : tous les comptes sont égaux et
isolés par les politiques RLS (cf. supabase/schema.sql). Ce script passe par
l'inscription publique (clé anon), exactement comme l'écran « Créer un
compte » : le trigger `on_auth_user_created` crée le profil.

Usage :
    python tool/create_test_account.py adresse@exemple.com [mot_de_passe]

Sans mot de passe, il en génère un. Si la confirmation par email est active
(Authentication > Providers > Email > Confirm email), le compte n'est
utilisable qu'après le clic sur le lien reçu. Les identifiants sont affichés
une seule fois et ne sont écrits nulle part.
"""

import json
import secrets
import string
import sys
import urllib.error
import urllib.request
from pathlib import Path

ENV = Path(__file__).resolve().parent.parent / "env.json"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    email = sys.argv[1].strip()
    alphabet = string.ascii_letters + string.digits
    password = sys.argv[2] if len(sys.argv) > 2 else (
        "Cq-" + "".join(secrets.choice(alphabet) for _ in range(14)))

    env = json.loads(ENV.read_text(encoding="utf-8"))
    body = json.dumps({
        "email": email,
        "password": password,
        "data": {"full_name": "Compte Test"},
    }).encode()
    request = urllib.request.Request(
        env["SUPABASE_URL"].rstrip("/") + "/auth/v1/signup",
        data=body,
        headers={
            "apikey": env["SUPABASE_ANON_KEY"],
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        print(f"Échec ({error.code}) : {error.read().decode(errors='replace')}")
        return 1

    user = payload.get("user") or payload
    confirmed = bool(user.get("email_confirmed_at") or payload.get("access_token"))
    print(f"Email        : {email}")
    print(f"Mot de passe : {password}")
    print(f"Identifiant  : {user.get('id')}")
    print("Statut       : " + ("actif" if confirmed else
                              "en attente — clique le lien de confirmation reçu par email"))
    if not user.get("identities") and not confirmed:
        print("Attention : cette adresse a peut-être déjà un compte "
              "(Supabase masque ce cas). Utilise « Mot de passe oublié ».")
    return 0


if __name__ == "__main__":
    sys.exit(main())
