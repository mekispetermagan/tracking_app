import csv

with open("courses.csv", "r") as file:
    reader = csv.reader(file)
    content = [[cell for cell in row] for row in reader][1:]
courses = [
    [
        '{',
        f'    "name": "{row[1]}",',
        f'    "description": "{row[2]}",',
        f'    "country_id": {row[3]},',
        f'    "active": {row[4] == "TRUE"},',
        '},'
    ]
    for row in content
    ]
for course in courses:
    for line in course:
        print(line)