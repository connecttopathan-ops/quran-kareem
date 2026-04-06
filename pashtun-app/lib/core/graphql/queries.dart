const getCollectionsQuery = r'''
query GetCollections {
  collections(first: 20) {
    edges {
      node {
        id
        title
        handle
        image {
          url
          altText
        }
      }
    }
  }
}
''';

const getCollectionProductsQuery = r'''
query GetCollectionProducts($handle: String!, $first: Int!, $after: String) {
  collectionByHandle(handle: $handle) {
    title
    description
    image {
      url
      altText
    }
    products(first: $first, after: $after) {
      pageInfo {
        hasNextPage
        endCursor
      }
      edges {
        node {
          id
          handle
          title
          description
          vendor
          productType
          tags
          priceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
          compareAtPriceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
          images(first: 3) {
            edges {
              node {
                url
                altText
              }
            }
          }
          variants(first: 10) {
            edges {
              node {
                id
                title
                availableForSale
                quantityAvailable
                price {
                  amount
                  currencyCode
                }
                compareAtPrice {
                  amount
                  currencyCode
                }
                selectedOptions {
                  name
                  value
                }
              }
            }
          }
        }
      }
    }
  }
}
''';

const getProductByHandleQuery = r'''
query GetProductByHandle($handle: String!) {
  productByHandle(handle: $handle) {
    id
    handle
    title
    description
    descriptionHtml
    vendor
    productType
    tags
    priceRange {
      minVariantPrice {
        amount
        currencyCode
      }
    }
    compareAtPriceRange {
      minVariantPrice {
        amount
        currencyCode
      }
    }
    images(first: 10) {
      edges {
        node {
          url
          altText
          width
          height
        }
      }
    }
    variants(first: 30) {
      edges {
        node {
          id
          title
          availableForSale
          quantityAvailable
          price {
            amount
            currencyCode
          }
          compareAtPrice {
            amount
            currencyCode
          }
          selectedOptions {
            name
            value
          }
        }
      }
    }
    options {
      id
      name
      values
    }
    collections(first: 5) {
      edges {
        node {
          handle
          title
        }
      }
    }
  }
}
''';

const getRelatedProductsQuery = r'''
query GetRelatedProducts($handle: String!, $first: Int!) {
  productByHandle(handle: $handle) {
    collections(first: 1) {
      edges {
        node {
          products(first: $first) {
            edges {
              node {
                id
                handle
                title
                priceRange {
                  minVariantPrice { amount currencyCode }
                }
                compareAtPriceRange {
                  minVariantPrice { amount currencyCode }
                }
                images(first: 1) {
                  edges {
                    node { url altText }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
''';

const getCustomerOrdersQuery = r'''
query GetCustomerOrders($customerAccessToken: String!, $first: Int!) {
  customer(customerAccessToken: $customerAccessToken) {
    id
    firstName
    lastName
    email
    phone
    orders(first: $first) {
      edges {
        node {
          id
          orderNumber
          processedAt
          financialStatus
          fulfillmentStatus
          currentTotalPrice {
            amount
            currencyCode
          }
          lineItems(first: 20) {
            edges {
              node {
                title
                quantity
                variant {
                  id
                  title
                  price { amount currencyCode }
                  image { url altText }
                }
              }
            }
          }
          shippingAddress {
            address1
            address2
            city
            province
            country
            zip
          }
        }
      }
    }
  }
}
''';

const cartQuery = r'''
query GetCart($cartId: ID!) {
  cart(id: $cartId) {
    id
    checkoutUrl
    totalQuantity
    cost {
      totalAmount { amount currencyCode }
      subtotalAmount { amount currencyCode }
      totalTaxAmount { amount currencyCode }
    }
    discountCodes {
      code
      applicable
    }
    lines(first: 50) {
      edges {
        node {
          id
          quantity
          cost {
            totalAmount { amount currencyCode }
          }
          merchandise {
            ... on ProductVariant {
              id
              title
              price { amount currencyCode }
              compareAtPrice { amount currencyCode }
              product {
                id
                handle
                title
                images(first: 1) {
                  edges { node { url altText } }
                }
              }
              selectedOptions { name value }
            }
          }
        }
      }
    }
  }
}
''';
