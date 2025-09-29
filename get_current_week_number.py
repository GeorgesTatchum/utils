import datetime


current_date = datetime.date.today()

# Récupérer le numéro de la semaine ISO
num_semaine = current_date.isocalendar()[1]

print(f"Nous sommes actuellement en semaine {num_semaine}.")
