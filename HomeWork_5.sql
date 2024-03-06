--В цьому завданні ти будеш використовувати дані з чотирьох таблиць в БД:

--facebook_ads_basic_daily
--facebook_adset
--facebook_campaign
--google_ads_basic_daily
--Завдання (крок за кроком):

--В CTE запиті обʼєднай дані з наведених вище таблиць, щоб отримати:
--ad_date - дата показу реклами в Google та Facebook;
--url_parameters - частина URL з посилання кампаній, що включає в себе UTM параметри;
--spend, impressions, reach, clicks, leads, value - метрики кампаній та наборів оголошень у відповідні дні; !!! У випадку якщо в таблиці значення метрики відсутнє (тобто null), задай значення рівним нулю (тобто 0).
--З отриманого CTE зроби вибірку:
--ad_date - дата показу реклами;
--utm_campaign - значення параметра utm_campaign з поля utm_parameters, що задовольняє наступним умовам:
--воно зведене до нижнього регістра
--якщо значення utm_campaign в utm_parameters дорівнює ‘nan’, то воно має бути пустим (тобто null) в результуючій таблиці
--ПІДКАЗКА
--Використай функцію substring з регулярним виразом

--Загальна сума витрат, кількість показів, кількість кліків, а також загальний Value конверсій у відповідну дату по відповідній кампанії;
--CTR, CPC, CPM, ROMI у відповідну дату по відповідній кампанії. !!! При цьому, не використовуй WHERE, а уникни помилки ділення на нуль за допомогою оператора CASE.
--Формат здачі

create or replace function pg_temp.decode_url_part(p varchar) returns varchar as $$
select convert_from(cast(E'\\x'||string_agg(case when length(r.m[1])=1 then encode(convert_to(r.m[1], 'SQL_ASCII'),'hex')
	else substring(r.m[1] from 2 for 2) end,'') as bytea),'UTF8')
from regexp_matches($1,'%[0-9a-f][0-9a-f]|.','gi')as r(m);
$$ language sql immutable strict;



with 
FB as (select * from facebook_ads_basic_daily as fabd 
join facebook_adset as fa on fabd.adset_id = fa.adset_id
join facebook_campaign as fc on fabd.campaign_id = fc.campaign_id),
FG as (select ad_date,
              url_parameters,
              coalesce (spend,0) as spend,
              coalesce (impressions,0) as impressions,
              coalesce (reach,0)as reach,
              coalesce (clicks,0) as clicks,
              coalesce (leads,0) as leads,
              coalesce (value,0) as value from FB 
union all 
       select ad_date,
              url_parameters,
              coalesce (spend,0) as spend1,
              coalesce (impressions,0) as impressions1,
              coalesce (reach,0)as reach1,
              coalesce (clicks,0) as clicks1,
              coalesce (leads,0) as leads1,
              coalesce (value,0) as value1 from google_ads_basic_daily as gabd)
select ad_date, 
	   case when lower(substring(decode_url_part(url_parameters),'utm_campaign=([^&#$]+)')) ='nan' 
            then null 
            else lower(substring(decode_url_part(url_parameters),'utm_campaign=([^&#$]+)')) 
            end as utm_campaign,
       sum(spend) as ad_spend,
	   sum(impressions) as total_impressions,
	   sum(clicks) as total_clcics,
	   sum(value) as total_value,       
       case when sum(clicks)>0 then round(sum(spend)::numeric/sum(clicks),1) end as cpc,
	   case when sum(impressions)>0 then round(sum(spend)::numeric/sum(impressions)*1000.0,1)end as cpm,
	   case when sum(impressions)>0 then round(sum(clicks)/sum(impressions)::numeric,3) end as ctr,
	   case when sum(spend)>0 then round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) end as romi
from FG
group by ad_date, utm_campaign
order by ad_date