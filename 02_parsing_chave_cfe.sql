-- ============================================================
-- PROJETO: Parsing de Chave CFe-SAT Fiscal
-- AUTOR: Ana Carvalho | github.com/skycarvalho
-- DESCRIÇÃO: Script para destrinchar e estruturar as chaves
--            de acesso CFe-SAT em colunas individuais,
--            facilitando análise, auditoria e validação
--            de documentos fiscais eletrônicos.
-- TECNOLOGIA: SQL Server | SUBSTRING | Tabelas Temporárias
-- ============================================================


-- ============================================================
-- ESTRUTURA DA CHAVE CFe (44 caracteres após o prefixo "CFe")
--
-- Exemplo: CFe35240501707818000292590012724200489591824554
--
-- Posição | Tamanho | Conteúdo
-- ---------|---------|-----------------------------
--   3 -  4 |    2    | UF (código IBGE do estado)
--   5 -  8 |    4    | Ano e Mês (AAMM)
--   9 - 22 |   14    | CNPJ do emitente
--  23 - 24 |    2    | Modelo do documento fiscal (59 = CFe-SAT)
--  25 - 33 |    9    | Número de série do equipamento SAT
--  34 - 39 |    6    | Número do CFe-SAT (não utilizado)
--  40 - 47 |    8    | Código numérico aleatório (não utilizado)
--  48 - 48 |    1    | Dígito verificador (não utilizado)
-- ============================================================


-- ============================================================
-- ETAPA 1 — EXTRAÇÃO DAS CHAVES DA TABELA DE ORIGEM
-- ============================================================

SELECT numeroChave
INTO #COMPOSICAO_CFE
FROM CFeData_ComBase;


-- ============================================================
-- ETAPA 2 — CRIAÇÃO DA TABELA TEMPORÁRIA COM COLUNAS ESTRUTURADAS
-- ============================================================

CREATE TABLE #COMPOSICAO_CFE_TEMP (
    UF         VARCHAR(70),   -- Código da UF (ex: 35 = São Paulo)
    DT_PERIODO VARCHAR(70),   -- Período formatado (ex: 2024-05)
    CNPJ_EMIT  VARCHAR(70),   -- CNPJ do emitente (14 dígitos)
    MOD_DOC    VARCHAR(70),   -- Modelo do documento fiscal (ex: 59)
    N_SERIE    VARCHAR(70)    -- Número de série do equipamento SAT
);


-- ============================================================
-- ETAPA 3 — PARSING DA CHAVE POR POSIÇÃO (SUBSTRING)
-- Extrai cada campo pela posição exata dentro da chave
-- ============================================================

INSERT INTO #COMPOSICAO_CFE_TEMP (UF, DT_PERIODO, CNPJ_EMIT, MOD_DOC, N_SERIE)
SELECT
    -- UF: posições 3 e 4 (após o prefixo "CFe")
    SUBSTRING(numeroChave, 3, 2) AS UF,

    -- DT_PERIODO: posições 5-6 (ano) + posições 7-8 (mês), formatado como AAAA-MM
    FORMAT(CAST(SUBSTRING(numeroChave, 5, 4) AS INT), '0000')
        + '-' +
    FORMAT(CAST(SUBSTRING(numeroChave, 9, 2) AS INT), '00') AS DT_PERIODO,

    -- CNPJ: posições 9 a 22 (14 dígitos)
    SUBSTRING(numeroChave, 9, 14)  AS CNPJ_EMIT,

    -- Modelo do documento fiscal: posições 23 e 24
    SUBSTRING(numeroChave, 23, 2)  AS MOD_DOC,

    -- Número de série do SAT: posições 25 a 33
    SUBSTRING(numeroChave, 25, 9)  AS N_SERIE

FROM #COMPOSICAO_CFE;


-- ============================================================
-- ETAPA 4 — RESULTADO FINAL
-- ============================================================

SELECT * FROM #COMPOSICAO_CFE_TEMP
ORDER BY DT_PERIODO, CNPJ_EMIT;


-- ============================================================
-- LIMPEZA — remove tabelas temporárias ao finalizar
-- ============================================================

DROP TABLE #COMPOSICAO_CFE_TEMP;
DROP TABLE #COMPOSICAO_CFE;
