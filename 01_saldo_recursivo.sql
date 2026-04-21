-- ============================================================
-- PROJETO: Cálculo de Saldo Acumulado com CTE Recursiva
-- AUTOR: Ana Carvalho | github.com/skycarvalho
-- DESCRIÇÃO: Script desenvolvido para calcular o saldo de
--            estoque acumulado por produto e parceiro,
--            unindo saldo inicial com movimentações de
--            entradas e saídas via recursividade em SQL Server.
-- VOLUME: +1 milhão de linhas por execução
-- TECNOLOGIA: SQL Server | CTE Recursiva | Tabelas Temporárias
-- ============================================================


-- ============================================================
-- ETAPA 1 — VISUALIZAÇÃO DAS TABELAS DE ORIGEM
-- TBX_ANA_MOV: movimentações (entradas e saídas)
-- TBX_ANA_SIN: saldo inicial por produto/parceiro
-- ============================================================

SELECT * FROM TBX_ANA_MOV;
SELECT * FROM TBX_ANA_SIN;


-- ============================================================
-- ETAPA 2 — AJUSTE DE TIPOS DAS COLUNAS
-- Garante compatibilidade de tipos antes do processamento
-- ============================================================

ALTER TABLE TBX_ANA_MOV ALTER COLUMN ID_Parceiro   INT          NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN DT_Periodo    VARCHAR(7)   NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN Data          DATETIME     NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN NUMERO        BIGINT       NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN INDICADOR     INT          NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN ITEM          INT          NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN CODIGO        VARCHAR(60)  NULL;
ALTER TABLE TBX_ANA_MOV ALTER COLUMN QTD           NUMERIC(38,12) NULL;


PRINT 'INSERINDO DADOS INICIAIS';


-- ============================================================
-- ETAPA 3 — TABELA TEMPORÁRIA UNIFICADA
-- Une saldo inicial (TBX_ANA_SIN) com movimentações (TBX_ANA_MOV)
-- em uma estrutura única para processamento
-- ============================================================

CREATE TABLE #TBX_TEMP (
    ID_Parceiro  INT,
    DT_Periodo   VARCHAR(7),
    Data         DATETIME,
    Codigo       VARCHAR(60),
    QTD          NUMERIC(38,12),
    CHAVE        VARCHAR(44),
    NUMERO       BIGINT,
    ITEM         INT,
    IND_DESCR    VARCHAR(70),   -- Descrição do tipo: SALDO INICIAL / ENTRADAS / SAIDAS
    IND_ID       INT,           -- Indicador numérico do tipo de movimento
    QT_E         NUMERIC(38,12), -- Quantidade de entrada
    QT_S         NUMERIC(38,12)  -- Quantidade de saída
);


-- ============================================================
-- ETAPA 4 — INSERÇÃO DO SALDO INICIAL
-- Registros da TBX_ANA_SIN entram com IND_ID = 0
-- e descrição 'SALDO INICIAL'
-- ============================================================

INSERT INTO #TBX_TEMP (
    ID_Parceiro, DT_Periodo, Data, Codigo, QTD, IND_ID, IND_DESCR
)
SELECT
    ID_Parceiro,
    DT_Periodo,
    Data,
    Codigo,
    QTD,
    0,
    'SALDO INICIAL'
FROM TBX_ANA_SIN;


-- ============================================================
-- ETAPA 5 — INSERÇÃO DAS MOVIMENTAÇÕES
-- Registros da TBX_ANA_MOV com indicador original de E/S
-- ============================================================

INSERT INTO #TBX_TEMP (
    ID_Parceiro, DT_Periodo, Data, CHAVE, NUMERO, IND_ID, ITEM, Codigo, QTD
)
SELECT
    ID_Parceiro,
    DT_Periodo,
    Data,
    CHAVE,
    NUMERO,
    INDICADOR,
    ITEM,
    Codigo,
    QTD
FROM TBX_ANA_MOV;


-- ============================================================
-- ETAPA 6 — PADRONIZAÇÃO DOS INDICADORES
-- Converte o indicador numérico para descrição legível:
-- 0 → 1 (SALDO INICIAL já tratado separadamente)
-- 1 → ENTRADAS
-- 2 → SAIDAS
-- ============================================================

UPDATE #TBX_TEMP
SET IND_ID = CASE
    WHEN IND_ID = 0 THEN 1
    WHEN IND_ID = 1 THEN 2
    ELSE NULL
END
WHERE IND_DESCR IS NULL OR IND_DESCR <> 'SALDO INICIAL';

UPDATE #TBX_TEMP
SET IND_DESCR = CASE
    WHEN IND_DESCR = 'SALDO INICIAL' THEN 'SALDO INICIAL'
    WHEN IND_ID = 1                  THEN 'ENTRADAS'
    WHEN IND_ID = 2                  THEN 'SAIDAS'
    ELSE NULL
END;


-- ============================================================
-- ETAPA 7 — SEPARAÇÃO DE ENTRADAS E SAÍDAS EM COLUNAS
-- Facilita o cálculo acumulado na recursão
-- ============================================================

UPDATE #TBX_TEMP
SET
    QT_E = CASE WHEN IND_ID = 1 THEN QTD ELSE 0 END,
    QT_S = CASE WHEN IND_ID = 2 THEN QTD ELSE 0 END;


-- ============================================================
-- ETAPA 8 — ORDENAÇÃO PARA CONTROLE DA RECURSIVIDADE
-- ROW_NUMBER garante sequência correta por parceiro/produto/data
-- necessária para o JOIN recursivo funcionar linha a linha
-- ============================================================

PRINT 'CRIANDO ORDENAÇÃO PRÉ RECURSIVIDADE';

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            ID_Parceiro,
            CODIGO,
            DT_Periodo,
            IND_ID,
            Data,
            NUMERO,
            ITEM
    ) AS ID,
    *
INTO #TBX_TEMP_CONTROLE
FROM #TBX_TEMP;

SELECT * FROM #TBX_TEMP_CONTROLE ORDER BY ID;


-- ============================================================
-- ETAPA 9 — CTE RECURSIVA PARA SALDO ACUMULADO
-- Âncora: primeiro registro de cada produto/parceiro
-- Recursão: acumula saldo = saldo_anterior + entrada - saída
-- OPTION (MAXRECURSION 0): sem limite de recursão (alto volume)
-- ============================================================

PRINT 'INICIANDO CONSULTA RECURSIVA';

WITH SaldoRecursivo AS (

    -- ÂNCORA: primeiro registro de cada combinação produto/parceiro
    SELECT
        t.ID,
        t.ID_Parceiro,
        t.CODIGO,
        t.DT_Periodo,
        t.Data,
        t.IND_ID,
        t.IND_DESCR,
        t.QT_E,
        t.QT_S,
        CAST(t.QTD AS DECIMAL(18, 2)) AS QTD_SALDO
    FROM #TBX_TEMP_CONTROLE t
    WHERE t.ID IN (
        SELECT MIN(ID)
        FROM #TBX_TEMP_CONTROLE
        GROUP BY ID_Parceiro, CODIGO
    )

    UNION ALL

    -- RECURSÃO: saldo acumulado linha a linha
    SELECT
        t.ID,
        t.ID_Parceiro,
        t.CODIGO,
        t.DT_Periodo,
        t.Data,
        t.IND_ID,
        t.IND_DESCR,
        t.QT_E,
        t.QT_S,
        CAST(r.QTD_SALDO + t.QT_E - t.QT_S AS DECIMAL(18, 2)) AS QTD_SALDO
    FROM #TBX_TEMP_CONTROLE t
    INNER JOIN SaldoRecursivo r
        ON  t.ID          = r.ID + 1
        AND t.ID_Parceiro = r.ID_Parceiro
        AND t.CODIGO      = r.CODIGO
)

SELECT *
INTO #TBX_RESULTADO
FROM SaldoRecursivo
OPTION (MAXRECURSION 0); -- necessário para datasets com alto volume de linhas

PRINT 'CONSULTA RECURSIVA FINALIZADA';


-- ============================================================
-- ETAPA 10 — RESULTADO FINAL COM STATUS DE ESTOQUE
-- Apresenta o saldo final com classificação por status:
-- SALDO NEGATIVO → inconsistência a verificar
-- ESTOQUE ZERADO → produto sem saldo
-- ESTOQUE OK     → situação regular
-- ============================================================

SELECT
    ID              AS ID_Sequencial,
    ID_Parceiro     AS Parceiro,
    CODIGO          AS Produto,
    DT_Periodo      AS Período,
    DATA            AS DataMovimentação,
    IND_DESCR       AS TipoMovimentação,
    QT_E            AS Entradas,
    QT_S            AS Saídas,
    QTD_SALDO       AS SaldoFinal,
    CASE
        WHEN QTD_SALDO < 0 THEN 'SALDO NEGATIVO - VERIFICAR'
        WHEN QTD_SALDO = 0 THEN 'ESTOQUE ZERADO'
        ELSE                    'ESTOQUE OK'
    END             AS StatusEstoque
FROM #TBX_RESULTADO
ORDER BY Parceiro, Produto, ID_Sequencial;
