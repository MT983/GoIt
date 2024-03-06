--Це будуть дані з Facebook і Google з полями:

--ad_date
--url_parameters
--spend
--impressions
--reach
--clicks
--leads
--value
--Завдання (крок за кроком):

--Використай CTE з попереднього домашнього завдання в новому (другому) CTE для створення вибірки з такими даними:
--ad_month - перше число місяця дати показу реклами (отримане з ad_date);
--utm_campaign, загальна сума витрат, кількість показів, кількість кліків, value конверсій, CTR, CPC, CPM, ROMI - ті самі поля з тими самими умовами, що й у попередньому завданні.
--Зроби результуючу вибірку з наступними полями:
--ad_month;
--utm_campaign, загальна сума витрат, кількість показів, кількість кліків, value конверсій, CTR, CPC, CPM, ROMI;
--Для кожної utm_campaign в кожен місяць додай нове поле: ‘різниця CPM, CTR та ROMI’ в поточному місяці відносно попереднього у відсотках.


with facebook_google as (select ad_date, url_parameters, spend, impressions, reach, clicks, leads, value
                       from facebook_ads_basic_daily as fabd 
                       join facebook_adset as fa on fabd.adset_id=fa.adset_id              
                       join facebook_campaign fc on fabd.campaign_id = fc.campaign_id
                       union all
                       select ad_date, url_parameters, spend, impressions, reach, clicks, leads, value
                       from google_ads_basic_daily as gabd),
            fg_data as (select date(date_trunc('month', ad_date)) as ad_month,
						case when lower(substring(url_parameters, 'utm_campaign=([^&#$]+)'))!='nan' 
						then lower(substring(url_parameters, 'utm_campaign=([^&#$]+)')) end as utm_campaign,
						sum(spend) as spend,
						sum(impressions) as impressions, 
						sum(reach) as reach,
						sum(clicks) as clicks,
						sum(value) as value, 
						case when sum(clicks)>0 then round(sum(spend)::numeric/sum(clicks),1) end as cpc,
						case when sum(impressions)>0 then round(sum(spend)::numeric/sum(impressions)*1000.0,1)end as cpm,
						case when sum(impressions)>0 then round(sum(clicks)/sum(impressions)::numeric,3) end as ctr,
						case when sum(spend)>0 then round(100*(sum(value)-sum(spend))::numeric/sum(spend),1) end as romi
                        from facebook_google
                        group by 1, 2
                        order by 1)
select fg_data.ad_month, fg_data.utm_campaign, fg_data.spend, fg_data.impressions, fg_data.reach, fg_data.clicks, fg_data.value, fg_data.cpc,
	   case when fg_1m.cpc !=0 then round((fg_data.cpc-fg_1m.cpc)/fg_1m.cpc,2) end as cpc_1month,
       fg_data.cpm,
	   case when fg_1m.cpm!=0 then round((fg_data.cpm-fg_1m.cpm)/fg_1m.cpm,2) end as cpm_1month,
	   fg_data.ctr,
	   case when fg_1m.ctr!=0 then round((fg_data.ctr-fg_1m.ctr)/fg_1m.ctr,2) end as ctr_1month,
   	   fg_data.romi,
   	   case when fg_1m.romi!=0 then round((fg_data.romi-fg_1m.romi)/fg_1m.romi,2) end as romi_1month
from fg_data
left join fg_data as fg_1m on fg_data.ad_month=fg_1m.ad_month + interval '1 month' and fg_data.utm_campaign=fg_1m.utm_campaign
order by 2,1
