with

    -- Import CTEs
    base_customers as (select * from {{ source("jaffle_shop", "customers") }}),

    base_orders as (select * from {{ source("jaffle_shop", "orders") }}),

    base_payments as (select * from {{ source("stripe", "payment") }}),

    -- Logical CTEs
    -- staigin
    

    


    -- marts
    customer_order_history as (

        select

                customers.customer_id,
                customers.full_name,
                customers.surname,
                customers.givenname,
            min(order_date) as first_order_date,

            min(
                case
                    when orders.order_status not in ('returned', 'return_pending') then order_date
                end
            ) as first_non_returned_order_date,

            max(
                case
                    when orders.order_status not in ('returned', 'return_pending') then order_date
                end
            ) as most_recent_non_returned_order_date,

            coalesce(max(user_order_seq), 0) as order_count,

            coalesce(
                count(case when orders.order_status != 'returned' then 1 end), 0
            ) as non_returned_order_count,

            sum(
                case
                    when orders.order_status not in ('returned', 'return_pending')
                    then payments.payment_amount
                    else 0
                end
            ) as total_lifetime_value,

            sum(
                case
                    when orders.order_status not in ('returned', 'return_pending')
                    then payments.payment_amount
                    else 0
                end
            ) / nullif(
                count(
                    case when orders.order_status not in ('returned', 'return_pending') then 1 end
                ),
                0
            ) as avg_non_returned_order_value,

            array_agg(distinct orders.order_id) as order_ids

        from a

        join customers on orders.customer_id = customers.customers_id

        left outer join payments as c on orders.order_id = payments.order_id

        where orders.order_status not in ('pending') and payments.payment_status != 'fail'

        group by customers.customers_id, customers.full_name, customers.surname, customers.givenname

    ),

    -- Final CTEs 
    final as (

        select

            orders.order_id,
            orders.customer_id,
            customers.surname,
            customers.givenname,
            first_order_date,
            order_count,
            total_lifetime_value,
            payments.payment_amount as order_value_dollars,
            orders.order_status,
            payments.payment_status as payment_status

        from orders

        join customers on orders.customer_id = customers.customers_id

        join
            customer_order_history
            on orders.customer_id = customer_order_history.customer_id

        left outer join payments on orders.order_id = payments.order_id

        where payments.payment_status != 'fail'

    )

-- Simple Select Statement
select *
from final
