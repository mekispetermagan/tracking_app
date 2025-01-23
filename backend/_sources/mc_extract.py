import csv

with open("mentor_course_pairs.csv", "r") as file:
    reader = csv.reader(file)
    content = [[cell for cell in row] for row in reader][1:]
    pairs = [(int(row[0]), int(row[1])) for row in content]
    print(pairs)
    print(len(pairs))