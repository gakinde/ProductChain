`ProductChain`
==============

### A Comprehensive Smart Contract for Product Authenticity, Warranty, and Ownership Tracking

This Clarity smart contract provides a decentralized solution for manufacturers, owners, and third parties to verify product authenticity, manage warranties, and track ownership transfers. It establishes a transparent and immutable record of a product's lifecycle from its creation to its various owners, leveraging the Stacks blockchain for secure and reliable data management.

* * * * *

### Features

-   **Manufacturer Registration**: A contract owner can authorize specific principals (blockchain addresses) to be official manufacturers, ensuring only trusted entities can register products.

-   **Product Registration**: Authorized manufacturers can register new products, embedding critical information such as model, serial number, and warranty details directly onto the blockchain.

-   **Decentralized Ownership Transfer**: Product owners can transfer ownership to new principals. This feature records each transfer with a timestamp and reason, creating a clear and verifiable ownership history.

-   **Automated Warranty Verification**: The contract automatically calculates and verifies a product's warranty status based on its manufacturing date and a defined warranty period, preventing fraudulent claims.

-   **Warranty Claim Management**: Owners can submit detailed warranty claims, which are then recorded and managed by the system. Manufacturers can process and resolve these claims, with all actions immutably logged.

-   **Reputation Tracking**: The contract tracks manufacturer statistics, including the number of products registered and their claim resolution rates, providing a transparent reputation score for public access.

-   **Audit Trail**: Every significant event---product registration, ownership transfer, and warranty claims---is logged, creating a complete and tamper-proof audit trail for all registered products.

* * * * *

### Functions

#### Public Functions

-   `register-manufacturer(manufacturer principal)`: Allows the contract owner to authorize a new manufacturer.

-   `register-product(product-id (string-ascii 50), model (string-ascii 100), serial-number (string-ascii 50), warranty-months uint, initial-owner principal)`: Enables an authorized manufacturer to register a new product.

-   `transfer-ownership(product-id (string-ascii 50), new-owner principal, transfer-reason (string-ascii 100))`: Transfers ownership of a product from the current owner to a new one.

-   `process-warranty-claim(product-id (string-ascii 50), claim-type (string-ascii 100), claimant-contact (string-ascii 200))`: Allows a product owner to submit a warranty claim.

-   `resolve-warranty-claim(claim-id uint, resolution-notes (string-ascii 200))`: Allows the manufacturer of a product to resolve a pending warranty claim.

#### Private Functions

-   `is-valid-manufacturer(manufacturer principal)`: Internal helper function to check if a principal is an authorized manufacturer.

-   `get-warranty-expiration(manufacturing-date uint, warranty-months uint)`: Calculates the warranty expiration date based on the product's manufacturing date and warranty period.

-   `is-warranty-valid(product-id (string-ascii 50))`: Determines if a product's warranty is still active by comparing the current block height to the warranty expiration date.

-   `update-manufacturer-stats(manufacturer principal, stat-type (string-ascii 20))`: Updates a manufacturer's statistics for product registrations or warranty claims.

-   `calculate-reputation-score(total-claims uint, resolved-claims uint)`: Computes a manufacturer's reputation score based on their claim resolution rate.

-   `verify-product-authenticity(product-id (string-ascii 50))`: Confirms that a product is authentic and was registered by a valid manufacturer.

#### Read-Only Functions

-   `get-product-info(product-id (string-ascii 50))`: Retrieves the full product data for a given `product-id`.

-   `get-manufacturer-stats(manufacturer principal)`: Returns the reputation statistics for a specific manufacturer.

-   `get-warranty-claim(claim-id uint)`: Fetches a specific warranty claim record.

-   `get-transfer-history(transfer-id uint)`: Retrieves a specific ownership transfer record.

-   `is-product-authentic(product-id (string-ascii 50))`: Checks if a product is registered and authentic.

-   `get-warranty-status(product-id (string-ascii 50))`: Returns the warranty status (`"active"` or `"expired"`) of a product.

* * * * *

### How to Use

#### 1\. Contract Deployment

Deploy the `product-warranty-and-authenticity-verification-contract.clar` file to a Stacks blockchain. The `tx-sender` of this deployment transaction will become the `CONTRACT-OWNER`.

#### 2\. Manufacturer Onboarding

The contract owner must call the `register-manufacturer` function to onboard new manufacturers.

Code snippet

```
(as-contract
  (contract-call? .product-chain register-manufacturer 'ST1XJ6RC...4M0')
)

```

#### 3\. Product Registration

An authorized manufacturer can then register a product. The `initial-owner` can be the manufacturer or a third party.

Code snippet

```
(contract-call? .product-chain register-product "PROD-ABC-123" "Laptop Pro" "SN-XYZ-456" u24 'ST202D...4M0')

```

-   `product-id`: A unique identifier for the product.

-   `model`: Product model name.

-   `serial-number`: Product serial number.

-   `warranty-months`: Warranty period in months.

-   `initial-owner`: The principal (address) of the first owner.

#### 4\. Ownership Transfer

The current owner can transfer ownership of the product.

Code snippet

```
(contract-call? .product-chain transfer-ownership "PROD-ABC-123" 'ST1XJ6RC...4M0' "Resale on secondary market")

```

-   `product-id`: The unique identifier of the product.

-   `new-owner`: The principal of the new owner.

-   `transfer-reason`: A brief note on the reason for the transfer.

#### 5\. Warranty Claims

A product owner can submit a claim. The contract will automatically check if the warranty is valid.

Code snippet

```
(contract-call? .product-chain process-warranty-claim "PROD-ABC-123" "Screen repair" "Email: user@example.com")

```

#### 6\. Resolving Claims

The manufacturer of the product can resolve a claim, updating the claim's status.

Code snippet

```
(contract-call? .product-chain resolve-warranty-claim u1 "Repaired and shipped back to customer")

```

-   `claim-id`: The ID of the claim to be resolved. This is the value returned by the `process-warranty-claim` function.

* * * * *

### Data Structures

-   `manufacturers`: Maps a `principal` to a `bool` to track authorized manufacturers.

-   `products`: Stores detailed product information, including owner, manufacturer, and warranty data.

-   `warranty-claims`: Records each claim with a unique ID, product ID, claimant, and status.

-   `transfer-history`: Logs every ownership transfer, creating a full audit trail.

-   `manufacturer-stats`: Tracks key statistics for each manufacturer, such as products registered and claim resolution rates.

* * * * *

### Error Codes

-   `u100`: ERR-NOT-AUTHORIZED

-   `u101`: ERR-PRODUCT-EXISTS

-   `u102`: ERR-PRODUCT-NOT-FOUND

-   `u103`: ERR-NOT-MANUFACTURER

-   `u104`: ERR-NOT-OWNER

-   `u105`: ERR-WARRANTY-EXPIRED

-   `u106`: ERR-INVALID-TRANSFER

-   `u107`: ERR-MANUFACTURER-EXISTS

* * * * *

### Contribution

Feel free to open an issue or submit a pull request if you find a bug or have a suggestion for improvement.

* * * * *

### License

This smart contract is released under the MIT License.

![profile picture](https://lh3.googleusercontent.com/a/ACg8ocJ_vsw7TaCCeMuQ9lczLCzqs47IOD2H_aUfBxy6CgG3iFhEGtMA=s64-c)
