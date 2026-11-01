using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace BiljaktAPI;

// Biljakt's own sign-in tokens, given to people who sign in with Apple.
// Signed with Biljakt:TokenKey from the server's configuration if set; otherwise with a key derived from the
// database connection string, which only the server has. Changing the database password then signs out
// Apple users (they just sign in again).
public class BiljaktTokens
{
    public const string Scheme = "Biljakt";
    const string Issuer = "biljakt";
    static readonly TimeSpan Lifetime = TimeSpan.FromDays(180);

    readonly SymmetricSecurityKey key;
    public TokenValidationParameters ValidationParameters { get; }

    public BiljaktTokens(IConfiguration config)
    {
        var secret = config["Biljakt:TokenKey"];
        if (string.IsNullOrWhiteSpace(secret))
            secret = "biljakt-token:" + (config.GetConnectionString("Biljakt") ?? config.GetConnectionString("PlateRater") ?? "");
        key = new SymmetricSecurityKey(SHA256.HashData(Encoding.UTF8.GetBytes(secret)));
        ValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = Issuer,
            ValidAudience = Issuer,
            IssuerSigningKey = key,
            ClockSkew = TimeSpan.FromMinutes(2),
        };
    }

    public string Issue(string subject, string? email, string? name)
    {
        var claims = new List<Claim> { new("sub", subject) };
        if (!string.IsNullOrWhiteSpace(email)) claims.Add(new("email", email));
        if (!string.IsNullOrWhiteSpace(name)) claims.Add(new("name", name));
        var token = new JwtSecurityToken(Issuer, Issuer, claims, DateTime.UtcNow, DateTime.UtcNow.Add(Lifetime),
            new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// Checks Apple identity tokens against Apple's signing keys. The audience is the app's bundle ID.
public class AppleTokens(IConfiguration config)
{
    readonly ConfigurationManager<OpenIdConnectConfiguration> apple = new(
        "https://appleid.apple.com/.well-known/openid-configuration",
        new OpenIdConnectConfigurationRetriever(),
        new HttpDocumentRetriever());
    readonly string[] audiences = config.GetSection("Apple:BundleIds").Get<string[]>() ?? ["com.ibrahimaweidah.PlateRater"];

    public async Task<ClaimsPrincipal?> Validate(string identityToken)
    {
        if (identityToken.Length is 0 or > 5000) return null;
        try
        {
            var settings = await apple.GetConfigurationAsync(CancellationToken.None);
            var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
            return handler.ValidateToken(identityToken, new TokenValidationParameters
            {
                ValidIssuer = "https://appleid.apple.com",
                ValidAudiences = audiences,
                IssuerSigningKeys = settings.SigningKeys,
            }, out _);
        }
        catch (Exception)
        {
            return null;
        }
    }
}
