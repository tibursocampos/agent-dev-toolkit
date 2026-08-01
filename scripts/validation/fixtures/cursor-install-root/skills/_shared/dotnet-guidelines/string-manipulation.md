# Working with Strings in .NET

## Comparison

In C#, there are basically two types of string comparison:
- **Ordinal**: Interprets each character as a number, using its unicode values.
- **Culture-sensitive**: Interprets each character using a specific alphabet.

When comparing strings using the `==` operator or the `.Equals()` method, ordinal comparison is used by default.

```csharp
Console.WriteLine("Apple" == "Apple"); // True
Console.WriteLine("Apple".Equals("Apple")); // True
Console.WriteLine("Apple".Equals("apple")); // False
```

> [!WARNING]
> The difference is that the `.Equals()` method throws a `NullReferenceException` if the instance being compared is null.

In these cases, use the static method `string.Equals` which also allows changing the comparison type safely.

```csharp
string apple = null;
WriteLine(string.Equals(apple, "Apple", StringComparison.Ordinal)); // False
```

> [!TIP]
> Generally, ordinal comparison is much more performant than culture-sensitive comparison. Prefer `StringComparison.Ordinal` or `StringComparison.OrdinalIgnoreCase` for comparisons where linguistics is irrelevant. Avoid using `StringComparison.InvariantCulture` for most cases.

## Concatenation

To concatenate strings, prefer **string interpolation**.
```csharp
var lorem = "Lorem";
var ipsum = "ipsum";
Console.WriteLine($"{lorem} {ipsum}");
```

When the number of elements to be concatenated is dynamic (e.g., inside a loop), use the `System.Text.StringBuilder` class. It uses an internal buffer that reduces allocations, making it more efficient in these scenarios.

```csharp
var builder = new StringBuilder();
foreach (var value in values)
{
    if (IsValid(value))
    {  
        builder.Append(value);
    }
}
Console.WriteLine(builder.ToString());
```

## Manipulation (Span<T>)

Strings in .NET are immutable, meaning manipulation usually involves creating copies. Depending on the frequency, these allocations can cause Garbage Collector pressure.

You can reduce or completely avoid copies when manipulating strings safely using `Span<T>` and `ReadOnlySpan<char>`. This allows inspecting parts of the string without making new allocations via the `.Slice()` method.

```csharp
var helloWorld = "Hello world";
ReadOnlySpan<char> helloWorldSpan = helloWorld.AsSpan(); 

// Option 1: Allocating a new string (Avoid in hot paths)
string hello = helloWorld.Substring(startIndex: 0, length: 5);

// Option 2: Creating a slice without allocating
ReadOnlySpan<char> helloSpan = helloWorldSpan.Slice(start: 0, length: 5);
```

Using `Span<T>` combined with parsing methods (like `int.Parse(ReadOnlySpan<char>)`) is a highly effective way to optimize string-heavy processing, such as parsing CSV files.
