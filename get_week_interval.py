import argparse
import datetime

def get_week_range(year: int, week_number: int):
    """
    Retourne la plage de dates (lundi, dimanche) pour une semaine donnée.
    """
    monday = datetime.date.fromisocalendar(year, week_number, 1)
    sunday = datetime.date.fromisocalendar(year, week_number, 7)
    return monday, sunday

def main():
    parser = argparse.ArgumentParser(description="Obtenir la plage de dates d'un numéro de semaine ISO donné.")
    parser.add_argument("semaine", type=int, help="Numéro de semaine ISO (1-53)")
    parser.add_argument("-a", "--annee", type=int, default=datetime.date.today().year, help="Année (défaut : année en cours)")
    
    args = parser.parse_args()

    monday, sunday = get_week_range(args.annee, args.semaine)
    print(f"Semaine {args.semaine} de {args.annee}: du {monday} au {sunday}")

if __name__ == "__main__":
    main()
