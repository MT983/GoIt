--!!! В цьому завданні ти використаєш дані з чотирьох таблиць в БД:
--facebook_ads_basic_daily
--facebook_adset
--facebook_campaign
--Google_ads_basic_daily

--Завдання (крок за кроком):
--В SQL запиті в CTE обʼєднай дані з цих таблиць щоб отримати:
--ad_date - дата показу реклами в Google та Facebook
--campaign_name - назва кампанії в Google та Facebook
--spend, impressions, reach, clicks, leads, value - метрики кампаній та наборів оголошень у відповідні дні
--Аналогічно до завдання в попередній темі, з отриманої обʼєднаної таблиці (CTE) зроби вибірку:
--ad_date - дата показу реклами
--campaign_name - назва кампанії
--агреговані за датою та campaign_name значення для наступних показників:
--загальна сума витрат,
--кількість показів,
--кількість кліків,
--загальний Value конверсій
--Для виконання цього завдання згрупуй таблицю за полями ad_date та campaign_name

select ad_date, campaign_name,
sum(spend) as sp,
sum(impressions) as impr,
sum(clicks) as clc,
sum(value) as val,
round(sum(spend)::numeric/sum(clicks),1)  as cpc,
round(sum(spend)::numeric/sum(impressions)*1000.0,1) as cpm,
round(sum(clicks)/sum(impressions)::numeric,3) as ctr,
round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) as romi
from (with f_table as 
     (select ad_date, campaign_name, spend, impressions, reach, clicks, leads, value 
     from (select * from facebook_ads_basic_daily as fabd 
     join facebook_campaign as fc on fc.campaign_id = fabd.campaign_id)as f_abd),
     g_table as
     (select ad_date, campaign_name, spend, impressions, reach, clicks, leads, value 
     from google_ads_basic_daily as gabd)
select * from f_table
union all
select * from g_table) as total_FG
where clicks > 0 and spend > 0 and impressions > 0
group by ad_date, campaign_name
order by ad_date desc;

--Додаткове завдання для виконання за бажанням

--Опис додаткового завдання:

--Обʼєднавши дані з чотирьох таблиць, визнач кампанію з найвищим ROMI серед усіх кампаній з загальною сумою витрат більше 500 000.
--В цій кампанії визнач групу оголошень (adset_name) з найвищим ROMI.
--Результат завдання:

select adset_name, 
       sum(spend) as spe, 
       round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) as romi
from (with f_table as 
     (select adset_name, spend, value from(select * from facebook_ads_basic_daily as fabd 
       join facebook_adset as fa on fabd.adset_id = fa.adset_id) as f_abd),
     g_table as
     (select adset_name, spend, value 
     from google_ads_basic_daily as gabd)
select * from f_table
union all
select * from g_table) as total_FG
group by adset_name
having sum(spend) > 500000
order by romi desc
limit 1



