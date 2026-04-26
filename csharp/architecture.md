# C# Architecture Best Practices

## Table of Contents
1. [Modern C# Language Features](#modern-c-language-features)
2. [Code Quality and Analyzers](#code-quality-and-analyzers)
3. [ASP.NET Core Web API with Entity Framework Core](#aspnet-core-web-api-with-entity-framework-core)
4. [Project Structure](#project-structure)

---

## Modern C# Language Features

### Overview
Modern C# (12+) with .NET 8+ provides powerful features for building robust, type-safe applications with excellent performance and developer experience.

### Best Practices

#### 1. Nullable Reference Types (C# 8+)
```csharp
// ✅ Enable nullable reference types in project file
// <Nullable>enable</Nullable>

// Explicit nullability
public class UserService
{
    // Non-nullable reference type
    private readonly ILogger<UserService> _logger;
    
    // Nullable reference type
    private string? _cachedData;
    
    public UserService(ILogger<UserService> logger)
    {
        _logger = logger; // Must be initialized
    }
    
    public User? FindUser(int id)
    {
        // May return null
        return _database.Users.FirstOrDefault(u => u.Id == id);
    }
    
    public User GetUser(int id)
    {
        // Never returns null - caller can rely on this
        return _database.Users.First(u => u.Id == id);
    }
}

// ❌ Old approach - no null safety
public User FindUser(int id)
{
    return _database.Users.FirstOrDefault(u => u.Id == id); // Might be null!
}
```

#### 2. Records for DTOs and Value Objects (C# 9+)
```csharp
// ✅ Modern approach - immutable by default
public record UserDto(int Id, string Username, string Email, bool IsActive);

// Record with validation
public record CreateUserRequest
{
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string Password { get; init; }
}

// Record with methods
public record User(int Id, string Username, string Email)
{
    public bool IsValid() => !string.IsNullOrWhiteSpace(Username) 
                            && Email.Contains('@');
}

// Primary constructor for classes (C# 12+)
public class UserService(IUserRepository repository, ILogger<UserService> logger)
{
    private readonly IUserRepository _repository = repository;
    private readonly ILogger<UserService> _logger = logger;
    
    public async Task<User?> GetUserAsync(int id)
    {
        _logger.LogInformation("Fetching user {UserId}", id);
        return await _repository.GetByIdAsync(id);
    }
}

// ❌ Old approach - verbose
public class UserDto
{
    public int Id { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public bool IsActive { get; set; }
    
    public override bool Equals(object obj) { /* boilerplate */ }
    public override int GetHashCode() { /* boilerplate */ }
}
```

#### 3. Pattern Matching (C# 7-12)
```csharp
// ✅ Modern pattern matching
public decimal CalculateDiscount(Order order) => order switch
{
    { TotalAmount: > 1000, CustomerTier: "Gold" } => 0.20m,
    { TotalAmount: > 1000 } => 0.15m,
    { CustomerTier: "Gold" } => 0.10m,
    { Items.Count: > 10 } => 0.05m,
    _ => 0m
};

// Type patterns with null checks
public string GetUserDisplay(object? user) => user switch
{
    User { IsActive: true } u => $"{u.Username} (Active)",
    User u => $"{u.Username} (Inactive)",
    null => "No user",
    _ => "Invalid user type"
};

// List patterns (C# 11+)
public bool IsValidSequence(int[] numbers) => numbers switch
{
    [] => false,
    [var single] => single > 0,
    [var first, .. var rest, var last] => first < last,
    _ => true
};
```

#### 4. Init-Only Properties and Required Members (C# 9+, 11+)
```csharp
// ✅ Modern approach
public class User
{
    // Required properties (C# 11+)
    public required int Id { get; init; }
    public required string Username { get; init; }
    public required string Email { get; init; }
    
    // Optional with init
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
    public bool IsActive { get; init; } = true;
}

// Usage
var user = new User
{
    Id = 1,
    Username = "john",
    Email = "john@example.com"
    // CreatedAt and IsActive use defaults
};

// user.Id = 2; // ❌ Compile error - init-only
```

#### 5. Collection Expressions (C# 12+)
```csharp
// ✅ Modern collection initialization
int[] numbers = [1, 2, 3, 4, 5];
List<string> names = ["Alice", "Bob", "Charlie"];

// Spread operator
int[] moreNumbers = [..numbers, 6, 7, 8];
List<string> allNames = [..names, "David", "Eve"];

// Empty collections
List<int> empty = [];
```

#### 6. Target-Typed New Expressions (C# 9+)
```csharp
// ✅ Concise instantiation
List<User> users = new();
Dictionary<string, int> ages = new();

// In method calls
ProcessUsers(new List<User> { user1, user2 });
// becomes
ProcessUsers(new() { user1, user2 });
```

#### 7. File-Scoped Namespaces (C# 10+)
```csharp
// ✅ Modern approach - one less level of indentation
namespace MyApp.Services;

public class UserService
{
    // Implementation
}

// ❌ Old approach
namespace MyApp.Services
{
    public class UserService
    {
        // Implementation
    }
}
```

#### 8. Global Using Directives (C# 10+)
```csharp
// GlobalUsings.cs
global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading.Tasks;
global using Microsoft.EntityFrameworkCore;
global using Microsoft.Extensions.Logging;

// Now available in all files without explicit using statements
```

#### 9. String Interpolation and Raw String Literals (C# 11+)
```csharp
// ✅ Interpolated strings
var message = $"User {username} logged in at {DateTime.Now:yyyy-MM-dd HH:mm:ss}";

// Raw string literals (C# 11+) - great for JSON, SQL, etc.
var json = """
    {
        "id": 1,
        "username": "john",
        "email": "john@example.com"
    }
    """;

// Interpolated raw strings
var query = $$"""
    SELECT * FROM Users
    WHERE Username = '{{username}}'
    AND CreatedAt > '{{date}}'
    """;
```

#### 10. Generic Attributes (C# 11+)
```csharp
// ✅ Modern approach
[MyAttribute<int>]
public class MyClass { }

public class MyAttribute<T> : Attribute
{
    public Type Type => typeof(T);
}

// ❌ Old approach
[MyAttribute(typeof(int))]
public class MyClass { }
```

#### 11. Async Streams (C# 8+)
```csharp
// ✅ Async enumeration
public async IAsyncEnumerable<User> GetUsersStreamAsync(
    [EnumeratorCancellation] CancellationToken cancellationToken = default)
{
    await foreach (var user in _repository.GetAllAsync().WithCancellation(cancellationToken))
    {
        // Process each user as it arrives
        yield return user;
    }
}

// Usage
await foreach (var user in userService.GetUsersStreamAsync())
{
    Console.WriteLine(user.Username);
}
```

---

## Code Quality and Analyzers

### Recommended Tools Stack

#### 1. .NET SDK Analyzers and Code Style

**.editorconfig** - Define code style rules
```ini
root = true

[*.cs]
# Language features
csharp_prefer_simple_using_statement = true:suggestion
csharp_prefer_braces = true:warning
csharp_style_namespace_declarations = file_scoped:warning
csharp_style_prefer_method_group_conversion = true:suggestion
csharp_style_prefer_top_level_statements = true:suggestion
csharp_style_expression_bodied_methods = when_on_single_line:suggestion
csharp_style_expression_bodied_constructors = false:suggestion
csharp_style_expression_bodied_operators = when_on_single_line:suggestion
csharp_style_expression_bodied_properties = true:suggestion
csharp_style_expression_bodied_indexers = true:suggestion
csharp_style_expression_bodied_accessors = true:suggestion
csharp_style_expression_bodied_lambdas = true:suggestion
csharp_style_expression_bodied_local_functions = when_on_single_line:suggestion

# Null checking
csharp_style_conditional_delegate_call = true:suggestion
csharp_style_prefer_null_check_over_type_check = true:suggestion

# Pattern matching
csharp_style_pattern_matching_over_as_with_null_check = true:suggestion
csharp_style_pattern_matching_over_is_with_cast_check = true:suggestion
csharp_style_prefer_switch_expression = true:suggestion
csharp_style_prefer_pattern_matching = true:suggestion
csharp_style_prefer_not_pattern = true:suggestion
csharp_style_prefer_extended_property_pattern = true:suggestion

# Code style
csharp_style_var_for_built_in_types = true:suggestion
csharp_style_var_when_type_is_apparent = true:suggestion
csharp_style_var_elsewhere = true:suggestion

# Formatting
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_indent_case_contents = true
csharp_indent_switch_labels = true
csharp_space_after_cast = false
csharp_space_after_keywords_in_control_flow_statements = true

# Naming conventions
dotnet_naming_rule.interfaces_should_be_prefixed_with_i.severity = warning
dotnet_naming_rule.interfaces_should_be_prefixed_with_i.symbols = interface
dotnet_naming_rule.interfaces_should_be_prefixed_with_i.style = begins_with_i

dotnet_naming_rule.private_fields_should_be_prefixed_with_underscore.severity = warning
dotnet_naming_rule.private_fields_should_be_prefixed_with_underscore.symbols = private_field
dotnet_naming_rule.private_fields_should_be_prefixed_with_underscore.style = begins_with_underscore

dotnet_naming_symbols.interface.applicable_kinds = interface
dotnet_naming_symbols.private_field.applicable_kinds = field
dotnet_naming_symbols.private_field.applicable_accessibilities = private

dotnet_naming_style.begins_with_i.capitalization = pascal_case
dotnet_naming_style.begins_with_i.required_prefix = I
dotnet_naming_style.begins_with_underscore.capitalization = camel_case
dotnet_naming_style.begins_with_underscore.required_prefix = _

# .NET Code Quality Rules
dotnet_code_quality_unused_parameters = all:suggestion
dotnet_diagnostic.CA1062.severity = warning  # Validate arguments
dotnet_diagnostic.CA1848.severity = suggestion  # Use LoggerMessage delegates
dotnet_diagnostic.CA2007.severity = none  # ConfigureAwait not needed in apps
```

**Project File Configuration**
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <AnalysisMode>All</AnalysisMode>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <ItemGroup>
    <!-- Code analyzers -->
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.*">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.507">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="SonarAnalyzer.CSharp" Version="9.*">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

#### 2. Code Formatting

**Using dotnet format (built-in)**
```bash
# Format code
dotnet format

# Check formatting without making changes
dotnet format --verify-no-changes

# Format specific folder
dotnet format ./src
```

#### 3. Static Analysis with Roslyn Analyzers

Enable in-depth analysis:
```xml
<PropertyGroup>
  <AnalysisLevel>latest-all</AnalysisLevel>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
</PropertyGroup>
```

#### 4. XML Documentation Comments
```csharp
/// <summary>
/// Retrieves a user by their unique identifier.
/// </summary>
/// <param name="userId">The unique identifier of the user.</param>
/// <param name="cancellationToken">Cancellation token.</param>
/// <returns>The user if found; otherwise, null.</returns>
/// <exception cref="DatabaseException">Thrown when database access fails.</exception>
public async Task<User?> GetUserByIdAsync(
    int userId, 
    CancellationToken cancellationToken = default)
{
    ArgumentOutOfRangeException.ThrowIfNegativeOrZero(userId);
    
    try
    {
        return await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
    }
    catch (Exception ex)
    {
        throw new DatabaseException($"Failed to retrieve user {userId}", ex);
    }
}
```

Enable XML documentation generation:
```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1591</NoWarn> <!-- Suppress missing XML comment warnings -->
</PropertyGroup>
```

---

## ASP.NET Core Web API with Entity Framework Core

### Technology Stack

- **ASP.NET Core 8.0**: Modern, high-performance web framework
- **Entity Framework Core 8.0**: Powerful ORM with LINQ support
- **Npgsql.EntityFrameworkCore.PostgreSQL**: PostgreSQL provider
- **Minimal APIs or Controllers**: Choose based on complexity
- **FluentValidation**: Request validation
- **MediatR**: CQRS pattern (optional)

### Architecture Layers

```
┌─────────────────────────────────────────┐
│      API Layer (Controllers/Endpoints)  │  ← HTTP Request Handling
├─────────────────────────────────────────┤
│      Service Layer (Business Logic)     │  ← Business Rules
├─────────────────────────────────────────┤
│   Repository Layer (Data Access)        │  ← Database Operations
├─────────────────────────────────────────┤
│      Entity Models (EF Core)            │  ← Domain Models
├─────────────────────────────────────────┤
│         PostgreSQL Database             │  ← Data Persistence
└─────────────────────────────────────────┘
```

### Implementation Example

#### 1. Database Configuration

**appsettings.json**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=mydb;Username=postgres;Password=password"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  }
}
```

**ApplicationDbContext.cs**
```csharp
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
    : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        
        // Global query filters
        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
    }

    // Override SaveChanges for audit fields
    public override async Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.Entity is IAuditableEntity 
                     && (e.State == EntityState.Added || e.State == EntityState.Modified));

        foreach (var entry in entries)
        {
            var entity = (IAuditableEntity)entry.Entity;
            
            if (entry.State == EntityState.Added)
            {
                entity.CreatedAt = DateTime.UtcNow;
            }
            
            entity.UpdatedAt = DateTime.UtcNow;
        }

        return await base.SaveChangesAsync(cancellationToken);
    }
}
```

#### 2. Entity Models

**User.cs**
```csharp
namespace MyApp.Domain.Entities;

public class User : IAuditableEntity
{
    public int Id { get; set; }
    public required string Username { get; set; }
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation properties
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}

// Base interface for audit tracking
public interface IAuditableEntity
{
    DateTime CreatedAt { get; set; }
    DateTime? UpdatedAt { get; set; }
}
```

**Entity Configuration (Fluent API)**
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MyApp.Infrastructure.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");
        
        builder.HasKey(u => u.Id);
        
        builder.Property(u => u.Username)
            .IsRequired()
            .HasMaxLength(50);
        
        builder.Property(u => u.Email)
            .IsRequired()
            .HasMaxLength(100);
        
        builder.Property(u => u.PasswordHash)
            .IsRequired()
            .HasMaxLength(256);
        
        builder.Property(u => u.CreatedAt)
            .HasDefaultValueSql("CURRENT_TIMESTAMP");
        
        // Indexes
        builder.HasIndex(u => u.Username).IsUnique();
        builder.HasIndex(u => u.Email).IsUnique();
        builder.HasIndex(u => u.IsActive);
        
        // Relationships
        builder.HasMany(u => u.Orders)
            .WithOne(o => o.User)
            .HasForeignKey(o => o.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
```

#### 3. DTOs with Records

**UserDtos.cs**
```csharp
namespace MyApp.Application.DTOs;

public record UserDto(
    int Id,
    string Username,
    string Email,
    bool IsActive,
    DateTime CreatedAt);

public record CreateUserRequest
{
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string Password { get; init; }
}

public record UpdateUserRequest
{
    public string? Username { get; init; }
    public string? Email { get; init; }
    public bool? IsActive { get; init; }
}

public record UserListResponse(
    List<UserDto> Users,
    int TotalCount,
    int PageNumber,
    int PageSize);
```

**Mapping Extensions**
```csharp
namespace MyApp.Application.Mappings;

public static class UserMappings
{
    public static UserDto ToDto(this User user) => new(
        Id: user.Id,
        Username: user.Username,
        Email: user.Email,
        IsActive: user.IsActive,
        CreatedAt: user.CreatedAt);
    
    public static User ToEntity(this CreateUserRequest request, string passwordHash) => new()
    {
        Username = request.Username,
        Email = request.Email,
        PasswordHash = passwordHash
    };
}
```

#### 4. Repository Layer

**IUserRepository.cs**
```csharp
namespace MyApp.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<List<User>> GetAllAsync(
        int pageNumber, 
        int pageSize, 
        CancellationToken cancellationToken = default);
    Task<int> GetCountAsync(CancellationToken cancellationToken = default);
    Task<User> AddAsync(User user, CancellationToken cancellationToken = default);
    Task UpdateAsync(User user, CancellationToken cancellationToken = default);
    Task DeleteAsync(User user, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(int id, CancellationToken cancellationToken = default);
}
```

**UserRepository.cs**
```csharp
using Microsoft.EntityFrameworkCore;

namespace MyApp.Infrastructure.Repositories;

public class UserRepository(ApplicationDbContext context) : IUserRepository
{
    private readonly ApplicationDbContext _context = context;

    public async Task<User?> GetByIdAsync(
        int id, 
        CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<User?> GetByEmailAsync(
        string email, 
        CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public async Task<List<User>> GetAllAsync(
        int pageNumber, 
        int pageSize, 
        CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .AsNoTracking()
            .OrderBy(u => u.Id)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

    public async Task<int> GetCountAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Users.CountAsync(cancellationToken);
    }

    public async Task<User> AddAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(User user, CancellationToken cancellationToken = default)
    {
        // Soft delete
        user.IsDeleted = true;
        await UpdateAsync(user, cancellationToken);
    }

    public async Task<bool> ExistsAsync(int id, CancellationToken cancellationToken = default)
    {
        return await _context.Users.AnyAsync(u => u.Id == id, cancellationToken);
    }
}
```

#### 5. Service Layer

**Result Pattern for Error Handling**
```csharp
namespace MyApp.Application.Common;

public record Result<T>
{
    public T? Value { get; init; }
    public bool IsSuccess { get; init; }
    public string? Error { get; init; }

    public static Result<T> Success(T value) => new() 
    { 
        Value = value, 
        IsSuccess = true 
    };
    
    public static Result<T> Failure(string error) => new() 
    { 
        IsSuccess = false, 
        Error = error 
    };
}
```

**IUserService.cs**
```csharp
namespace MyApp.Application.Interfaces;

public interface IUserService
{
    Task<Result<UserDto>> GetUserAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<UserListResponse>> GetUsersAsync(
        int pageNumber, 
        int pageSize, 
        CancellationToken cancellationToken = default);
    Task<Result<UserDto>> CreateUserAsync(
        CreateUserRequest request, 
        CancellationToken cancellationToken = default);
    Task<Result<UserDto>> UpdateUserAsync(
        int id, 
        UpdateUserRequest request, 
        CancellationToken cancellationToken = default);
    Task<Result<bool>> DeleteUserAsync(int id, CancellationToken cancellationToken = default);
}
```

**UserService.cs**
```csharp
using Microsoft.Extensions.Logging;

namespace MyApp.Application.Services;

public class UserService(
    IUserRepository repository,
    IPasswordHasher passwordHasher,
    ILogger<UserService> logger) : IUserService
{
    private readonly IUserRepository _repository = repository;
    private readonly IPasswordHasher _passwordHasher = passwordHasher;
    private readonly ILogger<UserService> _logger = logger;

    public async Task<Result<UserDto>> GetUserAsync(
        int id, 
        CancellationToken cancellationToken = default)
    {
        var user = await _repository.GetByIdAsync(id, cancellationToken);
        
        if (user is null)
        {
            _logger.LogWarning("User with ID {UserId} not found", id);
            return Result<UserDto>.Failure($"User with ID {id} not found");
        }

        return Result<UserDto>.Success(user.ToDto());
    }

    public async Task<Result<UserListResponse>> GetUsersAsync(
        int pageNumber, 
        int pageSize, 
        CancellationToken cancellationToken = default)
    {
        var users = await _repository.GetAllAsync(pageNumber, pageSize, cancellationToken);
        var totalCount = await _repository.GetCountAsync(cancellationToken);
        
        var response = new UserListResponse(
            Users: users.Select(u => u.ToDto()).ToList(),
            TotalCount: totalCount,
            PageNumber: pageNumber,
            PageSize: pageSize);

        return Result<UserListResponse>.Success(response);
    }

    public async Task<Result<UserDto>> CreateUserAsync(
        CreateUserRequest request, 
        CancellationToken cancellationToken = default)
    {
        // Check if email already exists
        var existingUser = await _repository.GetByEmailAsync(request.Email, cancellationToken);
        if (existingUser is not null)
        {
            _logger.LogWarning("User with email {Email} already exists", request.Email);
            return Result<UserDto>.Failure($"User with email {request.Email} already exists");
        }

        // Hash password
        var passwordHash = _passwordHasher.HashPassword(request.Password);
        
        // Create user entity
        var user = request.ToEntity(passwordHash);
        
        // Save to database
        var createdUser = await _repository.AddAsync(user, cancellationToken);
        
        _logger.LogInformation("Created user with ID {UserId}", createdUser.Id);
        
        return Result<UserDto>.Success(createdUser.ToDto());
    }

    public async Task<Result<UserDto>> UpdateUserAsync(
        int id, 
        UpdateUserRequest request, 
        CancellationToken cancellationToken = default)
    {
        var user = await _repository.GetByIdAsync(id, cancellationToken);
        
        if (user is null)
        {
            return Result<UserDto>.Failure($"User with ID {id} not found");
        }

        // Update fields
        if (request.Username is not null)
            user.Username = request.Username;
        
        if (request.Email is not null)
        {
            // Check email uniqueness
            var existingUser = await _repository.GetByEmailAsync(request.Email, cancellationToken);
            if (existingUser is not null && existingUser.Id != id)
            {
                return Result<UserDto>.Failure($"Email {request.Email} is already in use");
            }
            user.Email = request.Email;
        }
        
        if (request.IsActive.HasValue)
            user.IsActive = request.IsActive.Value;

        await _repository.UpdateAsync(user, cancellationToken);
        
        _logger.LogInformation("Updated user with ID {UserId}", id);
        
        return Result<UserDto>.Success(user.ToDto());
    }

    public async Task<Result<bool>> DeleteUserAsync(
        int id, 
        CancellationToken cancellationToken = default)
    {
        var user = await _repository.GetByIdAsync(id, cancellationToken);
        
        if (user is null)
        {
            return Result<bool>.Failure($"User with ID {id} not found");
        }

        await _repository.DeleteAsync(user, cancellationToken);
        
        _logger.LogInformation("Deleted user with ID {UserId}", id);
        
        return Result<bool>.Success(true);
    }
}
```

#### 6. API Layer - Controller Approach

**UsersController.cs**
```csharp
using Microsoft.AspNetCore.Mvc;

namespace MyApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class UsersController(IUserService userService) : ControllerBase
{
    private readonly IUserService _userService = userService;

    /// <summary>
    /// Get a user by ID.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The user data.</returns>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserDto>> GetUser(
        int id, 
        CancellationToken cancellationToken)
    {
        var result = await _userService.GetUserAsync(id, cancellationToken);
        
        return result.IsSuccess 
            ? Ok(result.Value) 
            : NotFound(new { error = result.Error });
    }

    /// <summary>
    /// Get all users with pagination.
    /// </summary>
    /// <param name="pageNumber">Page number (1-based).</param>
    /// <param name="pageSize">Number of items per page.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>List of users.</returns>
    [HttpGet]
    [ProducesResponseType(typeof(UserListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<UserListResponse>> GetUsers(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var result = await _userService.GetUsersAsync(pageNumber, pageSize, cancellationToken);
        
        return Ok(result.Value);
    }

    /// <summary>
    /// Create a new user.
    /// </summary>
    /// <param name="request">User creation data.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The created user.</returns>
    [HttpPost]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserDto>> CreateUser(
        [FromBody] CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _userService.CreateUserAsync(request, cancellationToken);
        
        if (!result.IsSuccess)
        {
            return Conflict(new { error = result.Error });
        }

        return CreatedAtAction(
            nameof(GetUser),
            new { id = result.Value!.Id },
            result.Value);
    }

    /// <summary>
    /// Update an existing user.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <param name="request">Updated user data.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The updated user.</returns>
    [HttpPatch("{id:int}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserDto>> UpdateUser(
        int id,
        [FromBody] UpdateUserRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _userService.UpdateUserAsync(id, request, cancellationToken);
        
        return result.IsSuccess
            ? Ok(result.Value)
            : result.Error!.Contains("not found")
                ? NotFound(new { error = result.Error })
                : Conflict(new { error = result.Error });
    }

    /// <summary>
    /// Delete a user.
    /// </summary>
    /// <param name="id">The user ID.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>No content on success.</returns>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteUser(
        int id,
        CancellationToken cancellationToken)
    {
        var result = await _userService.DeleteUserAsync(id, cancellationToken);
        
        return result.IsSuccess
            ? NoContent()
            : NotFound(new { error = result.Error });
    }
}
```

#### 7. API Layer - Minimal API Approach (Alternative)

**UserEndpoints.cs**
```csharp
namespace MyApp.API.Endpoints;

public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/users")
            .WithTags("Users")
            .WithOpenApi();

        group.MapGet("/{id:int}", GetUser)
            .WithName("GetUser")
            .Produces<UserDto>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound);

        group.MapGet("/", GetUsers)
            .Produces<UserListResponse>(StatusCodes.Status200OK);

        group.MapPost("/", CreateUser)
            .Produces<UserDto>(StatusCodes.Status201Created)
            .Produces(StatusCodes.Status409Conflict);

        group.MapPatch("/{id:int}", UpdateUser)
            .Produces<UserDto>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound);

        group.MapDelete("/{id:int}", DeleteUser)
            .Produces(StatusCodes.Status204NoContent)
            .Produces(StatusCodes.Status404NotFound);
    }

    private static async Task<IResult> GetUser(
        int id,
        IUserService userService,
        CancellationToken cancellationToken)
    {
        var result = await userService.GetUserAsync(id, cancellationToken);
        return result.IsSuccess
            ? Results.Ok(result.Value)
            : Results.NotFound(new { error = result.Error });
    }

    private static async Task<IResult> GetUsers(
        int pageNumber,
        int pageSize,
        IUserService userService,
        CancellationToken cancellationToken)
    {
        var result = await userService.GetUsersAsync(pageNumber, pageSize, cancellationToken);
        return Results.Ok(result.Value);
    }

    private static async Task<IResult> CreateUser(
        CreateUserRequest request,
        IUserService userService,
        CancellationToken cancellationToken)
    {
        var result = await userService.CreateUserAsync(request, cancellationToken);
        
        return result.IsSuccess
            ? Results.CreatedAtRoute("GetUser", new { id = result.Value!.Id }, result.Value)
            : Results.Conflict(new { error = result.Error });
    }

    private static async Task<IResult> UpdateUser(
        int id,
        UpdateUserRequest request,
        IUserService userService,
        CancellationToken cancellationToken)
    {
        var result = await userService.UpdateUserAsync(id, request, cancellationToken);
        
        return result.IsSuccess
            ? Results.Ok(result.Value)
            : result.Error!.Contains("not found")
                ? Results.NotFound(new { error = result.Error })
                : Results.Conflict(new { error = result.Error });
    }

    private static async Task<IResult> DeleteUser(
        int id,
        IUserService userService,
        CancellationToken cancellationToken)
    {
        var result = await userService.DeleteUserAsync(id, cancellationToken);
        
        return result.IsSuccess
            ? Results.NoContent()
            : Results.NotFound(new { error = result.Error });
    }
}
```

#### 8. Program.cs - Application Setup

```csharp
using Microsoft.EntityFrameworkCore;
using MyApp.API.Endpoints;
using MyApp.Application.Interfaces;
using MyApp.Application.Services;
using MyApp.Infrastructure.Data;
using MyApp.Infrastructure.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers(); // If using controllers
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Database
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(5),
                errorCodesToAdd: null);
            npgsqlOptions.CommandTimeout(30);
        }));

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();

// Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();

// Map endpoints
app.MapControllers(); // If using controllers
app.MapUserEndpoints(); // If using minimal APIs

app.MapHealthChecks("/health");

// Apply migrations on startup (development only)
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await dbContext.Database.MigrateAsync();
}

app.Run();
```

### Multi-Tenancy

All data in the system is scoped to a tenant. Every table includes a `tenant_id` column, and every API request must include an `X-Tenant-ID` header. All queries and mutations are filtered by tenant.

#### 1. Tenant ID from Request Header
```csharp
// Middleware or extension to extract tenant ID from request header
public static class TenantExtensions
{
    public const string TenantHeaderName = "X-Tenant-ID";

    public static Guid GetTenantId(this HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue(TenantHeaderName, out var tenantHeader)
            || !Guid.TryParse(tenantHeader, out var tenantId))
        {
            throw new BadHttpRequestException("X-Tenant-ID header is required and must be a valid UUID");
        }
        return tenantId;
    }
}

// Usage in a controller or minimal API endpoint
app.MapPost("/api/customers", async (HttpContext context, CreateCustomerRequest request, ICustomerService service) =>
{
    var tenantId = context.GetTenantId();
    var result = await service.CreateCustomerAsync(tenantId, request);
    return Results.Created($"/api/customers/{result.Id}", result);
});
```

#### 2. Entity Base Class with Tenant ID
```csharp
// All entities inherit from this base
public abstract class TenantEntity
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class Customer : TenantEntity
{
    public required string Name { get; set; }
    public required string Email { get; set; }
    public string Status { get; set; } = "active";
    public decimal Balance { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
```

#### 3. Global Query Filter for Tenant Isolation
```csharp
// In ApplicationDbContext - apply tenant filter to all tenant-scoped entities
public class ApplicationDbContext : DbContext
{
    private readonly Guid _tenantId;

    public ApplicationDbContext(DbContextOptions options, IHttpContextAccessor httpContextAccessor)
        : base(options)
    {
        _tenantId = httpContextAccessor.HttpContext?.GetTenantId() ?? Guid.Empty;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply global tenant filter to all TenantEntity subclasses
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            if (typeof(TenantEntity).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .HasQueryFilter(
                        BuildTenantFilter(entityType.ClrType));
            }
        }
    }

    private LambdaExpression BuildTenantFilter(Type entityType)
    {
        var parameter = Expression.Parameter(entityType, "e");
        var tenantProperty = Expression.Property(parameter, nameof(TenantEntity.TenantId));
        var tenantValue = Expression.Property(Expression.Constant(this), nameof(_tenantId));
        var comparison = Expression.Equal(tenantProperty, tenantValue);
        return Expression.Lambda(comparison, parameter);
    }

    // Auto-set TenantId on new entities
    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        foreach (var entry in ChangeTracker.Entries<TenantEntity>()
            .Where(e => e.State == EntityState.Added))
        {
            entry.Entity.TenantId = _tenantId;
        }
        return await base.SaveChangesAsync(cancellationToken);
    }
}
```

#### 4. Repository Layer with Tenant Scope
```csharp
// Repositories automatically scoped to tenant via global query filter
public class CustomerRepository(ApplicationDbContext context) : ICustomerRepository
{
    // All queries are automatically filtered by tenant_id
    public async Task<Customer?> GetByIdAsync(Guid id)
    {
        return await context.Customers.FindAsync(id);
    }

    public async Task<List<Customer>> GetAllActiveAsync()
    {
        // No need to filter by tenant - global query filter handles it
        return await context.Customers
            .Where(c => c.Status == "active")
            .ToListAsync();
    }
}
```

#### 5. Indexing for Tenant Queries
```csharp
// Entity configuration - always include tenant_id in indexes
public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("customers");
        builder.HasKey(c => c.Id);

        // Composite index with tenant_id for all frequent queries
        builder.HasIndex(c => new { c.TenantId, c.Status });
        builder.HasIndex(c => new { c.TenantId, c.Email }).IsUnique();
    }
}
```

**Key rules:**
- Every table has a `tenant_id` column (UUID, NOT NULL)
- `X-Tenant-ID` header is required on every API request
- Global query filters ensure no cross-tenant data leakage
- `SaveChangesAsync` auto-populates `tenant_id` on inserts
- All indexes should include `tenant_id` as a leading column
- Cross-tenant access is never permitted

### Entity Framework Core Best Practices

#### 1. Use AsNoTracking for Read-Only Queries
```csharp
// ✅ Better performance for read-only queries
var users = await _context.Users
    .AsNoTracking()
    .ToListAsync();

// ❌ Unnecessary tracking overhead
var users = await _context.Users.ToListAsync();
```

#### 2. Avoid N+1 Queries with Include/ThenInclude
```csharp
// ✅ Single query with joins
var users = await _context.Users
    .Include(u => u.Orders)
        .ThenInclude(o => o.OrderItems)
    .ToListAsync();

// ❌ N+1 queries problem
var users = await _context.Users.ToListAsync();
foreach (var user in users)
{
    // Lazy loading causes additional query per user
    var orders = user.Orders.ToList();
}
```

#### 3. Use Pagination
```csharp
// ✅ Efficient pagination
var users = await _context.Users
    .OrderBy(u => u.Id)
    .Skip((pageNumber - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();
```

#### 4. Use Compiled Queries for Frequently Executed Queries
```csharp
private static readonly Func<ApplicationDbContext, int, Task<User?>> _getUserById =
    EF.CompileAsyncQuery((ApplicationDbContext context, int id) =>
        context.Users.FirstOrDefault(u => u.Id == id));

public async Task<User?> GetByIdAsync(int id)
{
    return await _getUserById(_context, id);
}
```

#### 5. Use SplitQuery for Multiple Collections
```csharp
// ✅ Multiple smaller queries instead of cartesian explosion
var users = await _context.Users
    .Include(u => u.Orders)
    .Include(u => u.Addresses)
    .AsSplitQuery()
    .ToListAsync();
```

#### 6. Migrations

```bash
# Add migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update

# Generate SQL script
dotnet ef migrations script

# Remove last migration (if not applied)
dotnet ef migrations remove
```

---

## Project Structure

### Recommended Structure (Clean Architecture)

```
MyApp.sln
│
├── src/
│   ├── MyApp.API/                          # Presentation Layer
│   │   ├── Controllers/
│   │   │   └── UsersController.cs
│   │   ├── Endpoints/
│   │   │   └── UserEndpoints.cs
│   │   ├── Middleware/
│   │   │   ├── ExceptionHandlingMiddleware.cs
│   │   │   └── RequestLoggingMiddleware.cs
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   └── MyApp.API.csproj
│   │
│   ├── MyApp.Application/                  # Application Layer
│   │   ├── Common/
│   │   │   ├── Result.cs
│   │   │   └── PagedResult.cs
│   │   ├── DTOs/
│   │   │   └── UserDtos.cs
│   │   ├── Interfaces/
│   │   │   ├── IUserService.cs
│   │   │   └── IUserRepository.cs
│   │   ├── Services/
│   │   │   └── UserService.cs
│   │   ├── Mappings/
│   │   │   └── UserMappings.cs
│   │   ├── Validators/
│   │   │   └── CreateUserRequestValidator.cs
│   │   └── MyApp.Application.csproj
│   │
│   ├── MyApp.Domain/                       # Domain Layer
│   │   ├── Entities/
│   │   │   ├── User.cs
│   │   │   ├── Order.cs
│   │   │   └── IAuditableEntity.cs
│   │   ├── Enums/
│   │   │   └── UserRole.cs
│   │   ├── Exceptions/
│   │   │   ├── DomainException.cs
│   │   │   └── ValidationException.cs
│   │   └── MyApp.Domain.csproj
│   │
│   └── MyApp.Infrastructure/               # Infrastructure Layer
│       ├── Data/
│       │   ├── ApplicationDbContext.cs
│       │   ├── Configurations/
│       │   │   └── UserConfiguration.cs
│       │   └── Migrations/
│       ├── Repositories/
│       │   └── UserRepository.cs
│       ├── Security/
│       │   └── PasswordHasher.cs
│       └── MyApp.Infrastructure.csproj
│
├── tests/
│   ├── MyApp.UnitTests/
│   │   ├── Services/
│   │   │   └── UserServiceTests.cs
│   │   └── MyApp.UnitTests.csproj
│   │
│   └── MyApp.IntegrationTests/
│       ├── Controllers/
│       │   └── UsersControllerTests.cs
│       ├── Fixtures/
│       │   └── WebApplicationFactory.cs
│       └── MyApp.IntegrationTests.csproj
│
├── .editorconfig
├── .gitignore
├── Directory.Build.props                   # Shared project properties
├── global.json
└── README.md
```

### Directory.Build.props (Shared Configuration)

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <LangVersion>12</LangVersion>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisMode>All</AnalysisMode>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.*">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

### Testing Strategy

#### Unit Tests with xUnit

**UserServiceTests.cs**
```csharp
using Moq;
using Xunit;

namespace MyApp.UnitTests.Services;

public class UserServiceTests
{
    private readonly Mock<IUserRepository> _mockRepository;
    private readonly Mock<IPasswordHasher> _mockPasswordHasher;
    private readonly Mock<ILogger<UserService>> _mockLogger;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _mockRepository = new Mock<IUserRepository>();
        _mockPasswordHasher = new Mock<IPasswordHasher>();
        _mockLogger = new Mock<ILogger<UserService>>();
        _sut = new UserService(_mockRepository.Object, _mockPasswordHasher.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetUserAsync_WhenUserExists_ReturnsSuccess()
    {
        // Arrange
        var userId = 1;
        var user = new User
        {
            Id = userId,
            Username = "testuser",
            Email = "test@example.com",
            PasswordHash = "hash",
            CreatedAt = DateTime.UtcNow
        };
        _mockRepository.Setup(r => r.GetByIdAsync(userId, default))
            .ReturnsAsync(user);

        // Act
        var result = await _sut.GetUserAsync(userId);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Value);
        Assert.Equal(userId, result.Value.Id);
        Assert.Equal("testuser", result.Value.Username);
    }

    [Fact]
    public async Task GetUserAsync_WhenUserDoesNotExist_ReturnsFailure()
    {
        // Arrange
        var userId = 999;
        _mockRepository.Setup(r => r.GetByIdAsync(userId, default))
            .ReturnsAsync((User?)null);

        // Act
        var result = await _sut.GetUserAsync(userId);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.Null(result.Value);
        Assert.Contains("not found", result.Error);
    }

    [Theory]
    [InlineData("john", "john@example.com", "password123")]
    [InlineData("jane", "jane@example.com", "securepass")]
    public async Task CreateUserAsync_WithValidData_ReturnsSuccess(
        string username, string email, string password)
    {
        // Arrange
        var request = new CreateUserRequest
        {
            Username = username,
            Email = email,
            Password = password
        };
        
        _mockRepository.Setup(r => r.GetByEmailAsync(email, default))
            .ReturnsAsync((User?)null);
        
        _mockPasswordHasher.Setup(h => h.HashPassword(password))
            .Returns("hashed_password");
        
        _mockRepository.Setup(r => r.AddAsync(It.IsAny<User>(), default))
            .ReturnsAsync((User u, CancellationToken ct) => u);

        // Act
        var result = await _sut.CreateUserAsync(request);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Value);
        Assert.Equal(username, result.Value.Username);
        Assert.Equal(email, result.Value.Email);
        _mockRepository.Verify(r => r.AddAsync(It.IsAny<User>(), default), Times.Once);
    }
}
```

#### Integration Tests

**UsersControllerTests.cs**
```csharp
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MyApp.IntegrationTests.Controllers;

public class UsersControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public UsersControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Remove the app's DbContext registration
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
                if (descriptor != null)
                {
                    services.Remove(descriptor);
                }

                // Add DbContext using in-memory database for testing
                services.AddDbContext<ApplicationDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });

                // Build service provider and seed database
                var sp = services.BuildServiceProvider();
                using var scope = sp.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                db.Database.EnsureCreated();
            });
        });

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task CreateUser_WithValidData_ReturnsCreated()
    {
        // Arrange
        var request = new CreateUserRequest
        {
            Username = "testuser",
            Email = "test@example.com",
            Password = "password123"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/users", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<UserDto>();
        Assert.NotNull(user);
        Assert.Equal(request.Username, user.Username);
        Assert.Equal(request.Email, user.Email);
    }

    [Fact]
    public async Task GetUser_WhenExists_ReturnsOk()
    {
        // Arrange - Create a user first
        var createRequest = new CreateUserRequest
        {
            Username = "john",
            Email = "john@example.com",
            Password = "password"
        };
        var createResponse = await _client.PostAsJsonAsync("/api/users", createRequest);
        var createdUser = await createResponse.Content.ReadFromJsonAsync<UserDto>();

        // Act
        var response = await _client.GetAsync($"/api/users/{createdUser!.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<UserDto>();
        Assert.NotNull(user);
        Assert.Equal(createdUser.Id, user.Id);
    }

    [Fact]
    public async Task GetUser_WhenDoesNotExist_ReturnsNotFound()
    {
        // Act
        var response = await _client.GetAsync("/api/users/99999");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
```

---

## Additional Best Practices

### 1. Dependency Injection

Use constructor injection consistently:
```csharp
// ✅ Good - constructor injection with primary constructor
public class UserService(
    IUserRepository repository,
    ILogger<UserService> logger) : IUserService
{
    public async Task<User?> GetUserAsync(int id)
    {
        logger.LogInformation("Fetching user {UserId}", id);
        return await repository.GetByIdAsync(id);
    }
}

// ❌ Bad - service locator anti-pattern
public class UserService
{
    public async Task<User?> GetUserAsync(int id, IServiceProvider serviceProvider)
    {
        var repository = serviceProvider.GetService<IUserRepository>();
        return await repository.GetByIdAsync(id);
    }
}
```

### 2. Configuration Management

Use strongly-typed configuration:
```csharp
// appsettings.json
{
  "JwtSettings": {
    "Secret": "your-secret-key",
    "Issuer": "your-issuer",
    "Audience": "your-audience",
    "ExpirationMinutes": 60
  }
}

// JwtSettings.cs
public class JwtSettings
{
    public required string Secret { get; init; }
    public required string Issuer { get; init; }
    public required string Audience { get; init; }
    public int ExpirationMinutes { get; init; }
}

// Program.cs
builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("JwtSettings"));

// Usage
public class TokenService(IOptions<JwtSettings> jwtSettings)
{
    private readonly JwtSettings _settings = jwtSettings.Value;
}
```

### 3. Structured Logging

```csharp
// ✅ Good - structured logging
_logger.LogInformation(
    "User {UserId} updated by {UpdatedBy} at {Timestamp}",
    userId, currentUser, DateTime.UtcNow);

// ❌ Bad - string interpolation
_logger.LogInformation($"User {userId} updated by {currentUser}");
```

### 4. Exception Handling Middleware

```csharp
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = exception switch
        {
            ValidationException => StatusCodes.Status400BadRequest,
            NotFoundException => StatusCodes.Status404NotFound,
            _ => StatusCodes.Status500InternalServerError
        };

        var response = new
        {
            error = exception.Message,
            statusCode = context.Response.StatusCode
        };

        return context.Response.WriteAsJsonAsync(response);
    }
}

// Register in Program.cs
app.UseMiddleware<ExceptionHandlingMiddleware>();
```

### 5. FluentValidation for Request Validation

```csharp
using FluentValidation;

public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required")
            .Length(3, 50).WithMessage("Username must be between 3 and 50 characters");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Passwoad)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters")
            .Matches(@"[A-Z]").WithMessage("Password must contain at least one uppercase letter")
            .Matches(@"[a-z]").WithMessage("Password must contain at least one lowercase letter")
            .Matches(@"\d").WithMessage("Password must contain at least one digit");
    }
}

// Register in Program.cs
builder.Services.AddValidatorsFromAssemblyContaining<CreateUserRequestValidator>();
```

---

## Summary

This architecture provides:

- ✅ **Modern C# Features**: Records, nullable reference types, pattern matching, primary constructors
- ✅ **Type Safety**: Compile-time null safety and strong typing
- ✅ **Code Quality**: Analyzers, formatters, and consistent standards
- ✅ **Clean Architecture**: Separation of concerns with clear layers
- ✅ **Testability**: Easy to mock and test each layer
- ✅ **Performance**: Async/await, compiled queries, connection pooling
- ✅ **Maintainability**: Consistent patterns and documentation
- ✅ **Developer Experience**: Excellent tooling and IDE support
- ✅ **Multi-Tenancy**: Tenant isolation via global query filters and header-based scoping

For production deployments, also consider:
- Authentication/Authorization (JWT, ASP.NET Core Identity)
- API versioning
- Rate limiting
- Response caching
- Distributed caching (Redis)
- Background jobs (Hangfire, Quartz.NET)
- Monitoring and telemetry (Application Insights, OpenTelemetry)
- CI/CD pipelines
- Docker containerization
- Health checks and readiness probes
