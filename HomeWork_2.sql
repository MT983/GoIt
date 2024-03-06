--Напиши SQL запит, що вибере з таблиці  facebook_ads_basic_daily наступні дані:
--ad_date - дата показу реклами
--campaign_id - унікальний ідентифікатор кампанії
--агреговані за датою та id кампанії значення для наступних показників:
--загальна сума витрат
--кількість показів
--кількість кліків
--загальний Value конверсій
--Використовуючи агреговані показники витрат та конверсій, розрахуй для кожної дати та id кампанії такі метрики:
--CPC
--CPM
--CTR
--ROMI
--Для виконання цього завдання згрупуй таблицю за полями ad_date та campaign_id.

--Примітка Щоб не отримувати помилку ділення на нуль, ти можеш відфільтрувати дані таким чином, щоб у знаменниках не могло бути нулів.

--Додаткове завдання для виконання за бажанням
--Опис додаткового завдання:

--Серед кампаній з загальною сумою витрат більше 500 000 в таблиці facebook_ads_basic_daily знайди кампанію з найвищим ROMI.

--Результат завдання:
--Знайдено ID кампанії з найвищим ROMI.
--SQL запит виконується та повертає результат.

select campaign_id, ad_date, 
sum(spend) as sp,
sum(impressions) as impr,
sum(clicks) as clc,
sum(value) as val,
round(sum(spend)::numeric/sum(clicks),1)  as cpc,
round(sum(spend)::numeric/sum(impressions)*1000.0,1) as cpm,
round(sum(clicks)/sum(impressions)::numeric,2) as ctr,
round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) as romi
from facebook_ads_basic_daily fabd
where clicks > 0 and spend > 0 and impressions > 0
group by campaign_id, ad_date 
order by ad_date desc;

select campaign_id, 
       sum(spend) as spe, 
       round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) as romi
from fabd f
group by campaign_id 
having sum(spend) > 500000
order by romi desc
limit 1



