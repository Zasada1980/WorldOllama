# 🛒 Руководство по системе покупки информации о компании

## 📋 Текущая реализация (company-check-local)

### 1️⃣ **Структура файлов**

```
src/
├── App.tsx                    # Главный компонент с логикой покупки
├── AdminPanel.tsx             # Панель админа (демо-данные заказов)
└── main.tsx                   # Root компонент с управлением isAdmin
```

---

## 🔍 Где найти логику покупки

### **Файл: `src/App.tsx`**

#### **1. Отображение планов (Pricing Tiers)**

**Строки 675-705** — Секция с ценами (внутри результатов поиска):

```tsx
{
  /* Pricing Tiers */
}
<div className="text-center">
  <h2 className="text-2xl font-bold mb-6">Choose Plan and Get Full Report</h2>
  <div className="grid md:grid-cols-4 gap-4">
    {[
      {
        name: "SILVER",
        price: 139,
        features: ["Full Extract", "Collateral List"],
      },
      {
        name: "BRONZE",
        price: 189,
        features: ["All from Silver", "Bank of Israel Check"],
      },
      {
        name: "GOLD",
        price: 299,
        features: ["All from Bronze", "Execution Office"],
        popular: true,
      },
      {
        name: "PLATINUM",
        price: 499,
        features: ["All from Gold", "Real Estate", "Full History"],
      },
    ].map((tier, i) => (
      <div
        key={i}
        className={`relative bg-white p-6 rounded-xl border ${
          tier.popular ? "border-blue-600 shadow-lg" : "border-gray-200"
        }`}
      >
        {tier.popular && (
          <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-xs px-3 py-1 rounded-full uppercase">
            Most Popular
          </div>
        )}
        <h3 className="font-bold text-lg mb-2">{tier.name}</h3>
        <div className="text-3xl font-bold text-blue-600 mb-4">
          ₪{tier.price}
        </div>
        <ul className="space-y-2 mb-6 text-sm text-left">
          {tier.features.map((f, j) => (
            <li key={j} className="flex items-start gap-2">
              <span className="text-green-600">✓</span>
              <span>{f}</span>
            </li>
          ))}
        </ul>
        <button
          className={`w-full py-2 rounded-lg font-medium cursor-pointer ${
            tier.popular
              ? "bg-blue-600 text-white hover:bg-blue-700"
              : "bg-gray-100 hover:bg-gray-200"
          }`}
        >
          Select
        </button>
      </div>
    ))}
  </div>
</div>;
```

**Строки 840-870** — Вторая секция с ценами (на отдельной странице):

```tsx
<div className="grid md:grid-cols-4 gap-6">
  {[
    {
      name: "SILVER",
      price: 139,
      features: ["Full Extract", "Collateral List", "Basic Data", "PDF Report"],
    },
    {
      name: "BRONZE",
      price: 189,
      features: [
        "All from Silver",
        "Bank of Israel Check",
        "Credit Score",
        "Financial Data",
      ],
    },
    {
      name: "GOLD",
      price: 299,
      features: [
        "All from Bronze",
        "Execution Office",
        "Court Cases",
        "Legal History",
      ],
      popular: true,
    },
    {
      name: "PLATINUM",
      price: 499,
      features: [
        "All from Gold",
        "Real Estate",
        "Full History",
        "Priority Support",
        "API Access",
      ],
    },
  ].map((tier, i) => (
    <div
      key={i}
      className={`relative bg-white p-6 rounded-xl border-2 ${
        tier.popular ? "border-blue-600 shadow-xl" : "border-gray-200"
      }`}
    >
      {/* ... */}
      <button
        onClick={() => alert(`Selected ${tier.name} plan - ₪${tier.price}`)} // ← ТЕКУЩАЯ ЛОГИКА
        className={`w-full py-3 rounded-lg font-medium cursor-pointer transition-colors ${
          tier.popular
            ? "bg-blue-600 text-white hover:bg-blue-700"
            : "bg-gray-100 hover:bg-gray-200"
        }`}
      >
        Select {tier.name}
      </button>
    </div>
  ))}
</div>
```

**🔴 ПРОБЛЕМА:** Кнопка сейчас только показывает `alert()` — реальной покупки НЕТ!

---

#### **2. Premium Information (блокировка данных)**

**Строки 614-640** — Блок с заблокированными данными для не-админов:

```tsx
<div className="relative">
  <h2 className="text-sm font-semibold text-red-600 mb-4 flex items-center gap-2">
    {!isAdmin && <Lock className="w-4 h-4" />}
    {isAdmin ? "🔓 Premium Information (Admin Access)" : "Premium Information"}
  </h2>
  <div
    className={`space-y-3 text-sm ${
      isAdmin ? "" : "opacity-30 blur-sm select-none"
    }`}
  >
    <div className="flex items-center gap-2 py-2 border-b">
      <span>Shareholders (5 owners)</span>
    </div>
    <div className="flex items-center gap-2 py-2 border-b">
      <span>Directors and CEO</span>
    </div>
    <div className="flex items-center gap-2 py-2 border-b">
      <span>Collateral (2 active)</span>
    </div>
  </div>
  {!isAdmin && (
    <div className="absolute inset-0 flex items-center justify-center">
      <div className="bg-white/95 px-6 py-3 rounded-xl shadow-lg border text-center">
        <Lock className="w-6 h-6 mx-auto mb-2 text-gray-400" />
        <p className="font-semibold text-sm">Locked Data</p>
      </div>
    </div>
  )}
</div>
```

**Логика:**

- Если `isAdmin === false` → данные blur + overlay с замком
- Если `isAdmin === true` → данные открыты

---

## 🎯 Полная реализация checkout (из архивной версии)

### **Файл: `ui-interface-archive/src/App.tsx`**

#### **State Management**

```tsx
const [view, setView] = useState<"home" | "preview" | "checkout" | "report">(
  "home"
);
const [selectedTier, setSelectedTier] = useState<any>(null);
const [userEmail, setUserEmail] = useState("");
const [isLoading, setIsLoading] = useState(false);
```

#### **Функция перехода к checkout**

```tsx
const goToCheckout = (tier: any) => {
  setSelectedTier(tier);
  setView("checkout");
};
```

#### **Функция обработки оплаты**

```tsx
const handlePayment = () => {
  if (!userEmail) return;
  setIsLoading(true);
  setTimeout(() => {
    setIsLoading(false);
    setView("report"); // Переход к полному отчёту
  }, 2000);
};
```

#### **Checkout UI (строки 278-355)**

```tsx
{
  view === "checkout" && selectedTier && (
    <div className="max-w-2xl mx-auto animate-in fade-in zoom-in-95 duration-300">
      <button
        onClick={() => setView("preview")}
        className="mb-6 text-muted-foreground hover:text-primary flex items-center gap-2"
      >
        <ArrowLeft className={`w-4 h-4 ${isRTL ? "rotate-180" : ""}`} />{" "}
        {t.checkout.backToTiers}
      </button>

      <Card className="overflow-hidden shadow-xl">
        <div className="bg-primary p-6 text-primary-foreground">
          <h2 className="text-2xl font-bold flex items-center gap-3">
            <CreditCard className="w-6 h-6" /> {t.checkout.title}
          </h2>
        </div>

        <div className="p-8">
          {/* Summary */}
          <div className="bg-muted rounded-xl p-6 mb-8 border">
            <h3 className="font-semibold mb-4">{t.checkout.summary.title}</h3>
            <div className="flex justify-between items-center mb-2">
              <span className="text-muted-foreground">
                {t.checkout.summary.tier}
              </span>
              <span className="font-bold text-lg">{selectedTier.name}</span>
            </div>
            <div className="flex justify-between items-center pt-2 border-t">
              <span className="text-muted-foreground">
                {t.checkout.summary.price}
              </span>
              <span className="font-bold text-2xl text-primary">
                ₪{selectedTier.price}
              </span>
            </div>
          </div>

          {/* Email Input */}
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium mb-2">
                {t.checkout.emailLabel}
              </label>
              <div className="relative">
                <Mail
                  className={`absolute top-3.5 w-5 h-5 text-muted-foreground ${
                    isRTL ? "right-3" : "left-3"
                  }`}
                />
                <Input
                  type="email"
                  value={userEmail}
                  onChange={(e) => setUserEmail(e.target.value)}
                  placeholder="user@example.com"
                  className={`${isRTL ? "pr-10" : "pl-10"}`}
                />
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                {t.checkout.emailHint}
              </p>
            </div>

            {/* Payment Method */}
            <div>
              <label className="block text-sm font-medium mb-3">
                {t.checkout.paymentMethod}
              </label>
              <div className="grid grid-cols-2 gap-4">
                <button className="flex flex-col items-center justify-center p-4 border-2 border-primary bg-primary/5 rounded-xl transition-all">
                  <CreditCard className="w-8 h-8 text-primary mb-2" />
                  <span className="font-semibold">Stripe</span>
                  <span className="text-xs text-muted-foreground">
                    {t.checkout.stripe}
                  </span>
                </button>
                <button className="flex flex-col items-center justify-center p-4 border hover:border-primary/50 rounded-xl transition-all opacity-60">
                  <span className="text-2xl mb-2">🇮🇱</span>
                  <span className="font-semibold">Bit</span>
                  <span className="text-xs text-muted-foreground">
                    {t.checkout.bit}
                  </span>
                </button>
              </div>
            </div>

            {/* Payment Button */}
            <Button
              onClick={handlePayment}
              disabled={!userEmail || isLoading}
              className="w-full py-6 font-bold shadow-lg"
            >
              {isLoading ? t.checkout.processing : t.checkout.checkoutButton}
            </Button>

            <div className="text-center text-xs text-muted-foreground flex items-center justify-center gap-1">
              <ShieldCheck className="w-3 h-3" /> {t.checkout.securityNote}
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
}
```

---

## 🔧 Что нужно сделать для внедрения покупки

### **Шаг 1: Добавить State Management в App.tsx**

```tsx
const [view, setView] = useState<"search" | "results" | "checkout" | "report">(
  "search"
);
const [selectedTier, setSelectedTier] = useState<any>(null);
const [userEmail, setUserEmail] = useState("");
const [isPurchasing, setIsPurchasing] = useState(false);
```

### **Шаг 2: Заменить onClick на кнопках Select**

**БЫЛО (строка 862):**

```tsx
onClick={() => alert(`Selected ${tier.name} plan - ₪${tier.price}`)}
```

**ДОЛЖНО БЫТЬ:**

```tsx
onClick={() => {
  setSelectedTier(tier);
  setView('checkout');
}}
```

### **Шаг 3: Добавить Checkout View**

```tsx
{
  view === "checkout" && selectedTier && (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl p-8 relative max-h-[90vh] overflow-y-auto">
        {/* Кнопка закрытия */}
        <button
          onClick={() => setView("results")}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
        >
          ✕
        </button>

        {/* Заголовок */}
        <div className="mb-6">
          <h2 className="text-2xl font-bold mb-2">Checkout</h2>
          <p className="text-gray-600">
            Complete your purchase to access full report
          </p>
        </div>

        {/* Summary */}
        <div className="bg-gray-50 rounded-xl p-6 mb-6">
          <h3 className="font-semibold mb-4">Order Summary</h3>
          <div className="flex justify-between mb-2">
            <span className="text-gray-600">Plan</span>
            <span className="font-bold">{selectedTier.name}</span>
          </div>
          <div className="flex justify-between pt-2 border-t">
            <span className="text-gray-600">Total</span>
            <span className="font-bold text-2xl text-blue-600">
              ₪{selectedTier.price}
            </span>
          </div>
        </div>

        {/* Email Input */}
        <div className="mb-6">
          <label className="block text-sm font-medium mb-2">
            Email Address
          </label>
          <input
            type="email"
            value={userEmail}
            onChange={(e) => setUserEmail(e.target.value)}
            placeholder="your-email@example.com"
            className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
          />
          <p className="text-xs text-gray-500 mt-2">
            Report will be sent to this email
          </p>
        </div>

        {/* Payment Method */}
        <div className="mb-6">
          <label className="block text-sm font-medium mb-3">
            Payment Method
          </label>
          <div className="grid grid-cols-2 gap-4">
            <button className="flex flex-col items-center p-4 border-2 border-blue-600 bg-blue-50 rounded-xl">
              <span className="text-3xl mb-2">💳</span>
              <span className="font-semibold">Stripe</span>
              <span className="text-xs text-gray-500">Credit Card</span>
            </button>
            <button className="flex flex-col items-center p-4 border rounded-xl opacity-60">
              <span className="text-3xl mb-2">🇮🇱</span>
              <span className="font-semibold">Bit</span>
              <span className="text-xs text-gray-500">Israeli Payment</span>
            </button>
          </div>
        </div>

        {/* Checkout Button */}
        <button
          onClick={handlePurchase}
          disabled={!userEmail || isPurchasing}
          className="w-full py-4 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {isPurchasing ? "Processing..." : `Pay ₪${selectedTier.price}`}
        </button>

        <p className="text-center text-xs text-gray-500 mt-4">
          🔒 Secure payment powered by Stripe
        </p>
      </div>
    </div>
  );
}
```

### **Шаг 4: Добавить функцию обработки покупки**

```tsx
const handlePurchase = React.useCallback(async () => {
  if (!userEmail || !selectedTier) return;

  setIsPurchasing(true);

  try {
    // Симуляция оплаты (2 секунды)
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // РЕАЛЬНАЯ ИНТЕГРАЦИЯ (когда backend готов):
    // const response = await fetch('/api/purchase', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({
    //     tier: selectedTier.name,
    //     price: selectedTier.price,
    //     email: userEmail,
    //     companyId: selectedCompany.companyId
    //   })
    // });
    // const data = await response.json();

    // Успешная оплата → активация премиум доступа
    setIsAdmin(true); // Открываем Premium данные
    sessionStorage.setItem("admin_authenticated", "true");

    alert(
      `✅ Payment successful!\n\nYou now have access to ${selectedTier.name} features.\nReceipt sent to: ${userEmail}`
    );

    setView("results");
    setSelectedTier(null);
    setUserEmail("");
  } catch (error) {
    alert("❌ Payment failed. Please try again.");
  } finally {
    setIsPurchasing(false);
  }
}, [userEmail, selectedTier]);
```

---

## 🎨 Где найти переводы (для checkout)

### **Файл: `ui-interface-archive/src/lib/translations.ts`**

```typescript
checkout: {
  title: "תשלום מאובטח",
  backToTiers: "חזרה לתוכניות",
  summary: {
    title: "סיכום הזמנה",
    tier: "תוכנית",
    price: "סכום לתשלום"
  },
  emailLabel: "כתובת אימייל",
  emailHint: "הדוח ישלח לאימייל זה",
  paymentMethod: "אמצעי תשלום",
  stripe: "כרטיס אשראי",
  bit: "העברה ישראלית",
  checkoutButton: "שלם עכשיו",
  processing: "מעבד תשלום...",
  securityNote: "תשלום מאובטח דרך Stripe"
}
```

---

## 📊 AdminPanel — Демо заказов

### **Файл: `src/AdminPanel.tsx`**

**Строки 111-114** — Демо-данные заказов:

```tsx
const MOCK_ORDERS = [
  {
    id: "ORD-7721",
    user: "Yossi Cohen",
    plan: "Gold",
    amount: "₪299",
    status: "Paid",
    date: "Today, 10:42",
  },
  {
    id: "ORD-7722",
    user: "Avi Ben-David",
    plan: "Silver",
    amount: "₪139",
    status: "Paid",
    date: "Today, 09:15",
  },
  {
    id: "ORD-7723",
    user: "Unknown",
    plan: "Bronze",
    amount: "₪189",
    status: "Failed",
    date: "Yesterday",
  },
  {
    id: "ORD-7724",
    user: "Sarah Levi",
    plan: "Platinum",
    amount: "₪499",
    status: "Refunded",
    date: "12 Oct 2024",
  },
];
```

**Отображение в Dashboard (строки 513-530):**

```tsx
<tbody>
  {MOCK_ORDERS.map((order) => (
    <tr key={order.id} className="hover:bg-slate-50 transition-colors">
      <td className="p-3 border-b text-xs text-slate-900 font-mono">
        {order.id}
      </td>
      <td className="p-3 border-b text-sm font-medium">{order.user}</td>
      <td className="p-3 border-b">
        <span
          className={`px-2 py-1 rounded text-xs font-bold ${
            order.plan === "Gold"
              ? "bg-yellow-100 text-yellow-700"
              : order.plan === "Platinum"
              ? "bg-slate-100 text-slate-700"
              : "bg-blue-100 text-blue-700"
          }`}
        >
          {order.plan}
        </span>
      </td>
      <td className="p-3 border-b font-semibold text-sm">{order.amount}</td>
      <td className="p-3 border-b">
        <span
          className={`px-2 py-1 rounded text-xs font-bold ${
            order.status === "Paid"
              ? "bg-green-100 text-green-700"
              : "bg-slate-100 text-slate-600"
          }`}
        >
          {order.status}
        </span>
      </td>
      <td className="p-3 border-b text-xs text-slate-500">{order.date}</td>
    </tr>
  ))}
</tbody>
```

---

## 🚀 Резюме

### **Текущая реализация:**

✅ Pricing tiers отображаются  
✅ Premium данные блокируются для не-админов  
✅ Admin может видеть все данные  
❌ **НЕТ реального checkout**  
❌ **НЕТ интеграции с платёжной системой**

### **Что нужно добавить:**

1. ✅ State для checkout flow (`view`, `selectedTier`, `userEmail`)
2. ✅ Функцию `handlePurchase()` с симуляцией оплаты
3. ✅ Checkout modal с формой email + выбор платёжки
4. ✅ После успешной оплаты → `setIsAdmin(true)` → открываются данные
5. 🔄 Backend API `/api/purchase` (для продакшна)
6. 🔄 Интеграция Stripe/Bit (реальные платёжные системы)

### **Файлы для изменения:**

- `src/App.tsx` — добавить checkout modal + handlePurchase
- `src/main.tsx` — уже готов (управление isAdmin)
- `src/AdminPanel.tsx` — уже показывает демо-заказы

---

**Создано:** 8 декабря 2025  
**Версия:** 1.0  
**Для проекта:** company-check-local
