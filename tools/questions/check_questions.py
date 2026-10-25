"""Checks data/questions.json against data/question_groups.json. Run from the repository root:
python tools/questions/check_questions.py"""
import json
import sys
from collections import Counter

questions = json.load(open("data/questions.json", encoding="utf-8"))
table = json.load(open("data/question_groups.json", encoding="utf-8"))
errors = []

ids = [q["id"] for q in questions]
if len(set(ids)) != len(ids):
    errors.append("ids are not unique")
group_of = {}
for group, cats in table["groups"].items():
    for cat in cats:
        if cat in group_of:
            errors.append(f"category listed twice: {cat}")
        group_of[cat] = group

counts = Counter()
unlisted = set()
for q in questions:
    if not isinstance(q["answer"], (int, float)) or isinstance(q["answer"], bool):
        errors.append(f"id {q['id']}: answer is not a number")
    for key in ("question_en", "question_tr"):
        if not str(q.get(key, "")).strip():
            errors.append(f"id {q['id']}: {key} is empty")
        elif len(q[key]) > 175:
            errors.append(f"id {q['id']}: {key} is longer than 175 characters")
    if q["category"] not in group_of:
        unlisted.add(q["category"])
    counts[group_of.get(q["category"], table["default"])] += 1

unused = set(group_of) - {q["category"] for q in questions}
if unused:
    errors.append(f"listed but not in the data: {sorted(unused)}")
print(len(questions), "questions;", dict(counts))
if unlisted:
    errors.append(f"categories in no group: {sorted(unlisted)}")
expected = {"atlas": 210, "archive": 240, "lab": 220, "stage": 330}
if dict(counts) != expected:
    errors.append(f"counts should be {expected}")
for e in errors:
    print("ERROR", e)
sys.exit(1 if errors else 0)
