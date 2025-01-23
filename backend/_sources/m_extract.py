import csv

with open("mentors.csv", "r") as file:
    reader = csv.reader(file)
    content = [[cell for cell in row] for row in reader][1:]
mentors = [
    [
        '{',
        f'    "first_name": "{row[1]}",',
        f'    "last_name": "{row[2]}",',
        f'    "country_id": {row[3]},',
        f'    "email": "{row[4]}",',
        f'    "preferred_language_Id": {row[5]},',
        f'    "active": {row[6] == "TRUE"},',
        '},'
    ]
    for row in content
    ]
for mentor in mentors:
    for line in mentor:
        print(line)