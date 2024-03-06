with first as (
select 
	date(date_trunc('month', payment_date)) as payment_month
	,gp.user_id 
	,age 
	,gp.game_name 
	,sum(revenue_amount_usd) as revenue_amount_usd 
	,language
from games_payments gp
left join games_paid_users gpu on gp.user_id=gpu.user_id
group by 1,2,3,4,6
order by 1,2),
second as(
select 
	*
    ,lag(date(date_trunc('month', payment_month))) over(partition by user_id order by date(date_trunc('month', payment_month))) as previous_payment_month
    ,lead(date(date_trunc('month', payment_month))) over(partition by user_id order by date(date_trunc('month', payment_month))) as next_payment_month
	,min(date(date_trunc('month', payment_month))) over(partition by user_id)as first_payment_month
from first),
third as (
select  
	user_id
	,age 
	,language
	,date(payment_month+ interval '1 month') as payment_month
	,null::numeric as revenue_amount_usd
	,case when  datediff('month',payment_month,next_payment_month)>1 or    
	            datediff('month',next_payment_month,payment_month) is null then 'churned' end as status
from second
where datediff('month',payment_month,next_payment_month)>1 or datediff('month',next_payment_month,payment_month) is null
union 
select 
	user_id
	,age 
	,language
	,payment_month
	,revenue_amount_usd
	,case when  datediff('month',payment_month,first_payment_month)=0 then 'new'
	      when  datediff('month',previous_payment_month,payment_month)>1 then 'back'
	      else 'active' end as status
from second
order by 1,2),
fourth as(
select 
	payment_month 
	,user_id 
	,age 
	,status
    ,revenue_amount_usd 
	,language 
	,case when status ='new' then user_id end as New_Users
	,case when status = 'new' then sum(revenue_amount_usd) end as New_MRR
    ,case when status in ('new','active','back') then user_id end as Paid_users
    ,case when status = 'churned' then user_id end as Churned_users
    ,case when status = 'churned' then lag (revenue_amount_usd) over (partition by user_id order by payment_month) end as Churned_revenue
    ,case when lag(status) over (partition by user_id order by payment_month) in ('new','active','back') then user_id end as Paid_users_previous
    ,lag (revenue_amount_usd) over (partition by user_id order by payment_month) as total_revenue_previous
    ,case when status ='active' then 
    						   case when (revenue_amount_usd-lag (revenue_amount_usd) over (partition by user_id order by payment_month))>0 
    						        then (revenue_amount_usd-lag (revenue_amount_usd) over (partition by user_id order by payment_month)) end end as Exp_MRR
    ,case when status ='active' then 
    						   case when (revenue_amount_usd-lag (revenue_amount_usd) over (partition by user_id order by payment_month))<0 
    						        then (revenue_amount_usd-lag (revenue_amount_usd) over (partition by user_id order by payment_month)) end end as Cont_MRR
	,row_number () over (partition by user_id order by payment_month) as LT_month
	,sum(revenue_amount_usd) over (order by payment_month) as Value_for_LTV
	,case when status = 'new' then row_number () over (partition by status order by payment_month) end as user_for_LTV
from third
where payment_month < '01-01-2023'
group by 1,2,3,4,5,6
order by 2,1)
select 
	payment_month
	--date(date_trunc('year', payment_month))
	,round(sum(revenue_amount_usd),0) as MRR_Revenue
	,count(distinct Paid_Users) as Paid_Users
	,round(sum(revenue_amount_usd)/count(distinct Paid_Users),0) as ARPPU
	,count(New_Users) as New_Users
	,round(sum(New_MRR),0) as New_MRR
	,count(Churned_users) as Churned_users
	,case when count(Paid_users_previous)=0 then null else round(count(Churned_users)/count(Paid_users_previous)::numeric,2) end as Churned_Rate
	,round(sum(Churned_Revenue),0) as Churned_Revenue
	,round(sum(Churned_Revenue)/sum(total_revenue_previous),2) as Revenue_Churned_Rate
	,round(sum(Exp_MRR),0) as Exp_MRR
	,round(sum(Cont_MRR),0) as Cont_MRR
	,round(avg(LT_month),1) as LT
	,round(max(Value_for_LTV)/max(user_for_LTV),0) as LTV
from fourth
group by 1
order by 1;