# 🗄️ SQL para QA — Estudos e Scripts Aplicados

Repositório com scripts SQL desenvolvidos e utilizados na prática em projetos de **Qualidade de Software**, **análise fiscal** e **gestão de dados em alta volumetria**.

Todos os scripts foram escritos para **SQL Server** e refletem situações reais de trabalho: validação de dados, auditoria de documentos fiscais, cálculos acumulados e investigação de inconsistências.

---

## 📁 Estrutura do Repositório

```
sql-qa/
├── 01_saldo_recursivo.sql       → Cálculo de saldo acumulado com CTE recursiva
├── 02_parsing_chave_cfe.sql     → Parsing e estruturação de chave CFe-SAT fiscal
└── README.md
```

---

## 📌 Scripts

### 01 — Cálculo de Saldo Acumulado com CTE Recursiva

**Contexto:** Projeto de controle de estoque por produto e parceiro, unindo saldo inicial com movimentações de entradas e saídas.

**Destaques técnicos:**
- CTE recursiva (`WITH SaldoRecursivo`) para acumulação linha a linha
- `ROW_NUMBER()` para controle da sequência de recursão
- Tabelas temporárias para staging e controle intermediário
- Tratamento de alto volume: `OPTION (MAXRECURSION 0)`
- Classificação final de status do estoque (OK / Zerado / Negativo)

**Volume:** +1 milhão de linhas por execução

---

### 02 — Parsing de Chave CFe-SAT Fiscal

**Contexto:** Análise e auditoria de documentos fiscais eletrônicos (CFe-SAT). A chave de acesso de 44 caracteres concentra diversas informações que precisam ser extraídas e estruturadas individualmente.

**Estrutura da chave CFe:**

| Posição | Conteúdo |
|--------|----------|
| 3 – 4 | UF (código IBGE) |
| 5 – 8 | Ano e Mês (AAMM) |
| 9 – 22 | CNPJ do emitente |
| 23 – 24 | Modelo do documento (59 = CFe-SAT) |
| 25 – 33 | Número de série do SAT |

**Destaques técnicos:**
- `SUBSTRING` posicional para extração precisa de campos
- `FORMAT` para padronização de datas
- Tabelas temporárias para processamento intermediário
- Preparado para processar milhares de chaves distintas

---

## 🛠️ Tecnologias

![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

---

## 👩‍💻 Sobre

Scripts desenvolvidos por **Ana Carvalho**, Analista de QA com foco em qualidade de dados, automação e confiabilidade de sistemas.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/anacarvalhocarolina)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/skycarvalho)
