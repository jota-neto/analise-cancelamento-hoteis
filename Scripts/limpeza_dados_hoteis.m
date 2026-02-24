let
    // 1. Conexão com a fonte de dados CSV original (dataset de reservas de hotéis)
    Fonte = Csv.Document(File.Contents("C:\Users\jnett\Downloads\hotel_bookings.csv"),[Delimiter=",", Columns=32, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    
    // 2. Promoção da primeira linha para cabeçalhos das colunas
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    
    // 3. Tipagem automática inicial dos dados feita pelo Power Query
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Cabeçalhos Promovidos",{{"hotel", type text}, {"is_canceled", Int64.Type}, {"lead_time", Int64.Type}, {"arrival_date_year", Int64.Type}, {"arrival_date_month", type text}, {"arrival_date_week_number", Int64.Type}, {"arrival_date_day_of_month", Int64.Type}, {"stays_in_weekend_nights", Int64.Type}, {"stays_in_week_nights", Int64.Type}, {"adults", Int64.Type}, {"children", Int64.Type}, {"babies", Int64.Type}, {"meal", type text}, {"country", type text}, {"market_segment", type text}, {"distribution_channel", type text}, {"is_repeated_guest", Int64.Type}, {"previous_cancellations", Int64.Type}, {"previous_bookings_not_canceled", Int64.Type}, {"reserved_room_type", type text}, {"assigned_room_type", type text}, {"booking_changes", Int64.Type}, {"deposit_type", type text}, {"agent", type text}, {"company", type text}, {"days_in_waiting_list", Int64.Type}, {"customer_type", type text}, {"adr", Int64.Type}, {"required_car_parking_spaces", Int64.Type}, {"total_of_special_requests", Int64.Type}, {"reservation_status", type text}, {"reservation_status_date", type date}}),
    
    // 4. Limpeza de Erros: Substitui erros de conversão na coluna crianças por 0 para manter a integridade da amostra
    #"Erros Substituídos na Coluna Crianças" = Table.ReplaceErrorValues(#"Tipo Alterado", {{"children", 0}}),
    
    // 5. Tradução Dinâmica: Aplica a matriz de tradução (De-Para) para padronizar os cabeçalhos em snake_case
    #"Tradução dos Cabeçalhos" = Table.RenameColumns(#"Erros Substituídos na Coluna Crianças", Table.ToRows(TabelaTraducao)),
    
    // 6. Tratamento de Nulos (Imputação): Substitui valores 'NULL' por 0 em colunas críticas para análise estatística
    #"Valor NULL Substituído por 0" = Table.ReplaceValue(#"Tradução dos Cabeçalhos","NULL",0,Replacer.ReplaceValue,{"qtd_criancas", "id_agente", "id_empresa"}),
    
    // 7. Correção de Tipagem: Garante que as colunas tratadas sejam reconhecidas como números inteiros para cálculos
    #"Alteração de Tipo para Texto para Número Inteiro" = Table.TransformColumnTypes(#"Valor NULL Substituído por 0",{{"qtd_criancas", Int64.Type}, {"id_agente", Int64.Type}, {"id_empresa", Int64.Type}}),
    
    // 8. Agrupamento Estatístico: Define o Espaço Amostral (Contagem) e Eventos (Soma de Cancelamentos) por tipo de hotel
    #"Agrupamento das Colunas" = Table.Group(#"Alteração de Tipo para Texto para Número Inteiro", {"tipo_hotel"}, {{"total_reservas", each Table.RowCount(_), Int64.Type}, {"total_cancelamentos", each List.Sum([cancelado]), type nullable number}}),
    
    // 9. Cálculo de Probabilidade Frequentista: Cria a métrica de risco dividindo cancelamentos pelo total de reservas
    #"Cálculo de Probabilidade" = Table.AddColumn(#"Agrupamento das Colunas", "probabilidade_cancelamento", each [total_cancelamentos] / [total_reservas]),
    
    // 10. Formatação Final: Converte a métrica de probabilidade para o formato percentual
    #"Coluna Probabilidade Cancelamento Alterada para Percentual" = Table.TransformColumnTypes(#"Cálculo de Probabilidade",{{"probabilidade_cancelamento", Percentage.Type}})
in
    #"Coluna Probabilidade Cancelamento Alterada para Percentual"