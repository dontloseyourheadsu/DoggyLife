using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using DoggyLife;
using DoggyLife.Data.Database;
using SqliteWasmHelper;
using Microsoft.EntityFrameworkCore;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Services.AddSqliteWasmDbContextFactory<AppDbContext>(
  opts => opts.UseSqlite("Data Source=things.sqlite3"));

builder.Services.AddScoped(_ => new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) });

var host = builder.Build();
/*
// ✅ Run EnsureCreatedAsync before the app starts
using (var scope = host.Services.CreateScope())
{
    var dbFactory = scope.ServiceProvider.GetRequiredService<IDbContextFactory<AppDbContext>>();
    using var db = await dbFactory.CreateDbContextAsync();
    await db.Database.EnsureCreatedAsync();
}*/

await host.RunAsync();
