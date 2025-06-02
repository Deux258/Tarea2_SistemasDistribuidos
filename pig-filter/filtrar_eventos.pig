eventos = LOAD ;

filtrados = FILTER eventos BY severidad > 2;

STORE filtrados INTO '/data/eventos_filtrados.txt' USING PigStorage(',');