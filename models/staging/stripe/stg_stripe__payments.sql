
    paymets (
        select
        id as payment_id,
        orderid as order_id,
        status as payment_status,
        payments.payment_amount as payment_amount

        from base_payments

        
    ),