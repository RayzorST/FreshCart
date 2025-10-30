# routes/orders.py
@router.post("/", response_model=OrderResponse)
async def create_order(
    order_data: OrderCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Создать заказ с применением акций"""
    # Рассчитываем скидки
    promotion_service = PromotionService(db)
    cart_result = promotion_service.calculate_cart_discounts(
        order_data.items,
        current_user.id
    )
    
    # Создаем заказ
    order = Order(
        user_id=current_user.id,
        total_amount=cart_result['total_amount'],
        discount_amount=cart_result['discount_amount'],
        final_amount=cart_result['final_amount'],
        shipping_address=order_data.shipping_address,
        notes=order_data.notes
    )
    
    db.add(order)
    db.commit()
    db.refresh(order)
    
    # Добавляем товары заказа
    for item_data in cart_result['items']:
        order_item = OrderItem(
            order_id=order.id,
            product_id=item_data['product_id'],
            quantity=item_data['quantity'],
            price=item_data.get('discount_price', item_data['price']),
            applied_promotions=json.dumps(item_data.get('applied_promotions', []))
        )
        db.add(order_item)
    
    # Сохраняем примененные акции
    for promo_data in cart_result['applied_promotions']:
        order_promo = OrderPromotion(
            order_id=order.id,
            promotion_id=promo_data['promotion_id'],
            description=promo_data['name']
        )
        db.add(order_promo)
    
    db.commit()
    return order