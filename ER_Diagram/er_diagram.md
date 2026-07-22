# ER Diagram — Hospital Management System

```mermaid
erDiagram
    DEPARTMENTS {
        INT department_id PK
        VARCHAR department_name
        VARCHAR location
        VARCHAR head_doctor
    }

    DOCTORS {
        INT doctor_id PK
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR specialization
        INT department_id FK
        DECIMAL consultation_fee
        DATE hire_date
    }

    PATIENTS {
        INT patient_id PK
        VARCHAR first_name
        VARCHAR last_name
        DATE date_of_birth
        VARCHAR gender
        VARCHAR phone
        VARCHAR blood_type
    }

    APPOINTMENTS {
        INT appointment_id PK
        INT patient_id FK
        INT doctor_id FK
        DATE appointment_date
        VARCHAR diagnosis
        DECIMAL bill_amount
        VARCHAR status
    }

    DEPARTMENTS ||--o{ DOCTORS : "employs"
    DOCTORS ||--o{ APPOINTMENTS : "conducts"
    PATIENTS ||--o{ APPOINTMENTS : "attends"
```

## Relationship Explanations

| Relationship | Type | Meaning |
|---|---|---|
| DEPARTMENTS → DOCTORS | One-to-Many | One department employs many doctors |
| DOCTORS → APPOINTMENTS | One-to-Many | One doctor conducts many appointments |
| PATIENTS → APPOINTMENTS | One-to-Many | One patient attends many appointments |

The APPOINTMENTS table is the central fact table linking patients and doctors.
