from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional

from app.models.database import get_db
from app.models.product import Product, Category, ProductTag, Tag
from app.schemas.product import (
    ProductResponse, ProductCreate, ProductUpdate,
    CategoryResponse, CategoryCreate,
    TagResponse, TagCreate, ProductTagsUpdate,
    ProductResponse, ProductTagLinkResponse
)
from app.api.endpoints.auth import get_current_user, get_current_admin
from app.models.user import User

router = APIRouter()

@router.get("/categories", response_model=List[CategoryResponse])
async def get_categories(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Получение списка категорий"""
    categories = db.query(Category).offset(skip).limit(limit).all()
    return categories

@router.post("/categories", response_model=CategoryResponse)
async def create_category(
    category_data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создание категории (требует аутентификации)"""
    category = Category(**category_data.dict())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category

@router.get("/", response_model=List[ProductResponse])
async def get_products(
    skip: int = 0,
    limit: int = 100,
    category_id: Optional[int] = Query(None, description="Фильтр по категории"),
    search: Optional[str] = Query(None, description="Поиск по названию"),
    db: Session = Depends(get_db)
):
    """Получение списка товаров с фильтрацией"""
    query = db.query(Product).filter(Product.is_active == True)
    
    if category_id:
        query = query.filter(Product.category_id == category_id)
    
    if search:
        query = query.filter(Product.name.ilike(f"%{search}%"))
    
    products = query.offset(skip).limit(limit).all()
    return products

@router.get("/search", response_model=List[ProductResponse])
async def search_products(
    name: Optional[str] = Query(None, min_length=1, max_length=100),
    category_id: Optional[int] = Query(None),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Расширенный поиск продуктов
    """
    query = db.query(Product).filter(Product.is_active == True)
    
    if name:
        name_term = f"%{name.strip()}%"
        query = query.filter(Product.name.ilike(name_term))
    
    if category_id:
        query = query.filter(Product.category_id == category_id)
    
    products = query.offset(offset).limit(limit).all()
    return products

@router.get("/items/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: int,
    db: Session = Depends(get_db)
):
    """Получение товара по ID"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    return product

@router.post("/", response_model=ProductResponse)
async def create_product(
    product_data: ProductCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создание товара (требует аутентификации)"""

    if product_data.category_id:
        category = db.query(Category).filter(Category.id == product_data.category_id).first()
        if not category:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category not found"
            )
    
    product = Product(**product_data.dict())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.put("/items/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: int,
    product_data: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Обновление товара (требует аутентификации)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    update_data = product_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.commit()
    db.refresh(product)
    return product

@router.delete("/items/{product_id}")
async def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление товара (мягкое удаление)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    product.is_active = False
    db.commit()
    
    return {"message": "Product deleted successfully"}

@router.get("/tags", response_model=List[TagResponse])
async def get_tags(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = Query(None, description="Поиск по названию тега"),
    db: Session = Depends(get_db)
):
    """Получение списка тегов с количеством продуктов"""
    query = db.query(Tag)
    
    if search:
        query = query.filter(Tag.name.ilike(f"%{search}%"))

    tags = query.offset(skip).limit(limit).all()

    result = []
    for tag in tags:
        tag_data = TagResponse.from_orm(tag)
        result.append(tag_data)
    
    return result

@router.get("/tags/{tag_id}", response_model=TagResponse)
async def get_tag(
    tag_id: int,
    db: Session = Depends(get_db)
):
    """Получение тега по ID"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )
    
    tag_data = TagResponse.from_orm(tag)
    tag_data.products_count = db.query(ProductTag).filter(ProductTag.tag_id == tag.id).count()
    return tag_data

@router.post("/tags", response_model=TagResponse)
async def create_tag(
    tag_data: TagCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создание тега (требует аутентификации)"""
    existing_tag = db.query(Tag).filter(func.lower(Tag.name) == func.lower(tag_data.name)).first()
    if existing_tag:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tag with this name already exists"
        )
    
    tag = Tag(**tag_data.dict())
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag

@router.delete("/tags/{tag_id}")
async def delete_tag(
    tag_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление тега (требует аутентификации)"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )

    db.query(ProductTag).filter(ProductTag.tag_id == tag_id).delete()

    db.delete(tag)
    db.commit()
    
    return {"message": "Tag deleted successfully"}

@router.get("/items/{product_id}/tags", response_model=List[TagResponse])
async def get_product_tags(
    product_id: int,
    db: Session = Depends(get_db)
):
    """Получение тегов конкретного продукта"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    return [product_tag.tag for product_tag in product.product_tags]

@router.post("/items/{product_id}/tags", response_model=List[TagResponse])
async def add_tags_to_product(
    product_id: int,
    tags_data: ProductTagsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Добавление тегов к продукту (требует аутентификации)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    added_tags = []
    for tag_name in tags_data.tag_names:

        tag = db.query(Tag).filter(func.lower(Tag.name) == func.lower(tag_name)).first()
        if not tag:
            tag = Tag(name=tag_name.strip())
            db.add(tag)
            db.commit()
            db.refresh(tag)

        existing_link = db.query(ProductTag).filter(
            ProductTag.product_id == product_id,
            ProductTag.tag_id == tag.id
        ).first()
        
        if not existing_link:
            product_tag = ProductTag(product_id=product_id, tag_id=tag.id)
            db.add(product_tag)
            added_tags.append(tag)
    
    db.commit()
    return added_tags

@router.delete("/items/{product_id}/tags/{tag_id}")
async def remove_tag_from_product(
    product_id: int,
    tag_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Удаление тега у продукта (требует аутентификации)"""
    product_tag = db.query(ProductTag).filter(
        ProductTag.product_id == product_id,
        ProductTag.tag_id == tag_id
    ).first()
    
    if not product_tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found for this product"
        )
    
    db.delete(product_tag)
    db.commit()
    
    return {"message": "Tag removed from product successfully"}

@router.put("/items/{product_id}/tags", response_model=List[TagResponse])
async def set_product_tags(
    product_id: int,
    tags_data: ProductTagsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Установка тегов продукта (замена всех текущих тегов)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )

    db.query(ProductTag).filter(ProductTag.product_id == product_id).delete()

    new_tags = []
    for tag_name in tags_data.tag_names:
        tag = db.query(Tag).filter(func.lower(Tag.name) == func.lower(tag_name)).first()
        if not tag:
            tag = Tag(name=tag_name.strip())
            db.add(tag)
            db.commit()
            db.refresh(tag)
        
        product_tag = ProductTag(product_id=product_id, tag_id=tag.id)
        db.add(product_tag)
        new_tags.append(tag)
    
    db.commit()
    return new_tags

@router.get("/search/by-tags", response_model=List[ProductResponse])
async def search_products_by_tags(
    tags: List[str] = Query(..., description="Список тегов для поиска"),
    category_id: Optional[int] = Query(None, description="Фильтр по категории"),
    min_price: Optional[float] = Query(None, description="Минимальная цена"),
    max_price: Optional[float] = Query(None, description="Максимальная цена"),
    in_stock: Optional[bool] = Query(None, description="Только в наличии"),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Поиск продуктов по тегам"""
    query = db.query(Product).join(Product.product_tags).join(Tag)

    query = query.filter(Tag.name.in_(tags))

    if category_id:
        query = query.filter(Product.category_id == category_id)
    
    if min_price is not None:
        query = query.filter(Product.price >= min_price)
    
    if max_price is not None:
        query = query.filter(Product.price <= max_price)
    
    if in_stock:
        query = query.filter(Product.stock_quantity > 0)
    
    query = query.filter(Product.is_active == True)

    query = query.group_by(Product.id).having(func.count(Tag.id) >= len(tags))
    
    products = query.offset(skip).limit(limit).all()
    return products

@router.get("/tags/{tag_id}/products", response_model=List[ProductResponse])
async def get_products_by_tag(
    tag_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Получение всех продуктов с определенным тегом"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )
    
    products = db.query(Product).join(Product.product_tags).filter(
        ProductTag.tag_id == tag_id,
        Product.is_active == True
    ).offset(skip).limit(limit).all()
    
    return products

# В products.py добавим админ-эндпоинты

@router.get("/admin/products", response_model=List[ProductResponse])
async def get_all_products_admin(
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Получение всех товаров (включая неактивные) для админа"""
    query = db.query(Product)
    
    if not include_inactive:
        query = query.filter(Product.is_active == True)
    
    products = query.offset(skip).limit(limit).all()
    return products

@router.post("/admin/products", response_model=ProductResponse)
async def create_product_admin(
    product_data: ProductCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Создание товара (админ)"""
    # Проверяем категорию
    if product_data.category_id:
        category = db.query(Category).filter(Category.id == product_data.category_id).first()
        if not category:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category not found"
            )
    
    product_dict = product_data.dict(exclude={'tag_ids'})
    product = Product(**product_dict)
    
    if product_data.tag_ids:
        tags = db.query(Tag).filter(Tag.id.in_(product_data.tag_ids)).all()
        product.tags = tags
    
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.put("/admin/products/{product_id}", response_model=ProductResponse)
async def update_product_admin(
    product_id: int,
    product_data: ProductUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Обновление товара (админ)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Обновляем базовые поля
    update_data = product_data.dict(exclude_unset=True, exclude={'tag_ids'})
    for field, value in update_data.items():
        setattr(product, field, value)
    
    # Обновляем категорию если нужно
    if product_data.category_id is not None:
        if product_data.category_id == 0:  # Удаляем категорию
            product.category_id = None
        else:
            category = db.query(Category).filter(Category.id == product_data.category_id).first()
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Category not found"
                )
            product.category_id = product_data.category_id
    
    # Обновляем теги если они переданы
    if product_data.tag_ids is not None:
        tags = db.query(Tag).filter(Tag.id.in_(product_data.tag_ids)).all()
        product.tags = tags
    
    db.commit()
    db.refresh(product)
    return product

@router.delete("/admin/products/{product_id}")
async def delete_product_admin(
    product_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Удаление товара (админ)"""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Сначала очищаем связи с тегами
    product.tags = []
    db.commit()
    
    # Теперь удаляем сам товар
    db.delete(product)
    db.commit()
    
    return {"message": "Product deleted successfully"}

# В products.py добавим админ-эндпоинты для категорий

@router.get("/admin/categories", response_model=List[CategoryResponse])
async def get_all_categories_admin(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Получение всех категорий (админ)"""
    categories = db.query(Category).offset(skip).limit(limit).all()
    return categories

@router.post("/admin/categories", response_model=CategoryResponse)
async def create_category_admin(
    category_data: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Создание категории (админ)"""
    # Проверяем уникальность названия
    existing_category = db.query(Category).filter(func.lower(Category.name) == func.lower(category_data.name)).first()
    if existing_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category with this name already exists"
        )
    
    category = Category(**category_data.dict())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category

@router.put("/admin/categories/{category_id}", response_model=CategoryResponse)
async def update_category_admin(
    category_id: int,
    category_data: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Обновление категории (админ)"""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    # Проверяем уникальность названия (исключая текущую категорию)
    existing_category = db.query(Category).filter(
        func.lower(Category.name) == func.lower(category_data.name),
        Category.id != category_id
    ).first()
    if existing_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category with this name already exists"
        )

    for field, value in category_data.dict().items():
        setattr(category, field, value)
    
    db.commit()
    db.refresh(category)
    return category

@router.delete("/admin/categories/{category_id}")
async def delete_category_admin(
    category_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Удаление категории (админ)"""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )

    # Проверяем, есть ли товары в этой категории
    products_count = db.query(Product).filter(Product.category_id == category_id).count()
    if products_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete category with {products_count} products. Move products to another category first."
        )

    db.delete(category)
    db.commit()
    
    return {"message": "Category deleted successfully"}

# В products.py добавим админ-эндпоинты для тегов

@router.get("/admin/tags", response_model=List[TagResponse])
async def get_all_tags(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Получение всех тегов (админ)"""
    tags = db.query(Tag).all()

    #for tag in tags:
    #    tag.product_count = len(db.query(Product).where(tag in Product.product_tags).count())
    
    return tags

@router.post("/admin/tags", response_model=TagResponse)
async def create_tag(
    tag_data: TagCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Создание тега (админ)"""
    # Проверяем уникальность имени
    existing_tag = db.query(Tag).filter(Tag.name == tag_data.name).first()
    if existing_tag:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tag with this name already exists"
        )
    
    tag = Tag(**tag_data.dict())
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag

@router.put("/admin/tags/{tag_id}", response_model=TagResponse)
async def update_tag(
    tag_id: int,
    tag_data: TagCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Обновление тега (админ)"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )
    
    # Проверяем уникальность имени (если имя изменилось)
    if tag_data.name != tag.name:
        existing_tag = db.query(Tag).filter(Tag.name == tag_data.name).first()
        if existing_tag:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tag with this name already exists"
            )
    
    for field, value in tag_data.dict().items():
        setattr(tag, field, value)
    
    db.commit()
    db.refresh(tag)
    return tag

@router.delete("/admin/tags/{tag_id}")
async def delete_tag(
    tag_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Удаление тега (админ)"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )
    
    db.delete(tag)
    db.commit()
    return {"message": "Tag deleted successfully"}

@router.get("/admin/tags/{tag_id}/products", response_model=List[ProductResponse])
async def get_products_by_tag_admin(
    tag_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Получение продуктов по тегу (админ)"""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tag not found"
        )
    
    products = db.query(Product).join(Product.product_tags).filter(
        ProductTag.tag_id == tag_id
    ).offset(skip).limit(limit).all()
    
    return products