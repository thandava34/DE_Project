import json
import sqlite3
import unittest
from pathlib import Path
from jsonschema import Draft202012Validator, FormatChecker, ValidationError

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / 'contracts/healthcare.schema.json').read_text())


class SourceContracts(unittest.TestCase):
    def test_schema_is_valid(self):
        Draft202012Validator.check_schema(SCHEMA)
        self.assertEqual(set(SCHEMA['required']), set(SCHEMA['$defs']))
        self.assertEqual(len(SCHEMA['$defs']), 10)

    def validator(self, entity):
        return Draft202012Validator(SCHEMA['$defs'][entity], format_checker=FormatChecker())

    def test_claim_contract(self):
        claim = dict(claim_id='SYNTHETIC_C1', patient_id='SYNTHETIC_P1', visit_id='SYNTHETIC_V1',
                     status='Pending', billed=100, allowed=0, paid=0, updated_at='2026-01-01T00:00:00Z')
        self.validator('claims').validate(claim)
        for field, value in [('status', 'Unknown'), ('billed', -1), ('updated_at', 'invalid'), ('patient_id', '')]:
            with self.subTest(field=field), self.assertRaises(ValidationError):
                self.validator('claims').validate(dict(claim, **{field: value}))
        with self.assertRaises(ValidationError):
            self.validator('claims').validate(dict(claim, uncontracted_field='unexpected'))

    def test_source_ddl_and_integrity(self):
        with sqlite3.connect(':memory:') as connection:
            connection.execute('PRAGMA foreign_keys=ON')
            connection.executescript((ROOT / 'sql_scripts/source_schema.sql').read_text())
            connection.executescript((ROOT / 'sql_scripts/source_schema.sql').read_text())
            tables = {r[0] for r in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            self.assertEqual(tables, set(SCHEMA['$defs']))
            connection.execute("INSERT INTO insurance VALUES('SYNTHETIC_I1','Synthetic Insurance')")
            patient = ('SYNTHETIC_P1', '1990-01-01', 'F', 'NC', 'SYNTHETIC_I1', '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
            connection.execute('INSERT INTO patients VALUES(?,?,?,?,?,?,?)', patient)
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute('INSERT INTO patients VALUES(?,?,?,?,?,?,?)', patient)
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute('INSERT INTO patients VALUES(?,?,?,?,?,?,?)', ('P2', *patient[1:4], 'MISSING', *patient[5:]))
            connection.execute("INSERT INTO hospitals VALUES('H1','Synthetic Hospital','General','South')")
            connection.execute("INSERT INTO providers VALUES('DR1','General','H1','NC')")
            connection.execute("INSERT INTO diagnoses VALUES('D1','Synthetic diagnosis')")
            connection.execute("INSERT INTO visits VALUES('SYNTHETIC_V1','SYNTHETIC_P1','DR1','H1','Outpatient','2026-01-01T12:00:00Z','D1')")
            claim = ('C1','SYNTHETIC_P1','SYNTHETIC_V1','Pending',100,0,0,None,'2026-01-01T00:00:00Z')
            connection.execute('INSERT INTO claims VALUES(?,?,?,?,?,?,?,?,?)', claim)
            for bad in [('C2', *claim[1:4], -1, 0, 0, None, claim[-1]),
                        ('C3', *claim[1:6], 200, None, claim[-1]),
                        ('C4', *claim[1:3], 'Unknown', *claim[4:])]:
                with self.assertRaises(sqlite3.IntegrityError):
                    connection.execute('INSERT INTO claims VALUES(?,?,?,?,?,?,?,?,?)', bad)


if __name__ == '__main__':
    unittest.main()
