# Yeni ChatGPT / Work oturumu için prompt

Önce root `AGENTS.md` dosyasını canonical context router olarak oku. Amaç minimum gereksiz token ile maksimum doğruluk.

Kurallar:
1. Root `AGENTS.md` -> `docs/ai/CURRENT_STATE.md` -> yalnız görevle ilgili nearest local `AGENTS.md`.
2. Source/tests ile docs çelişirse source/tests kazanır.
3. Non-trivial işte `.agents/skills/task-packet/SKILL.md` kullan ve `docs/ai/EFFORT_ROUTER.md` ile T0/T1/T2/T3 risk sınıfını seç.
4. `REPO_MAP.md` yalnız navigation hint'tir; `DECISIONS.md`, `COMMANDS.md` ve diğer skill'leri yalnız ihtiyaç olduğunda yükle.
5. `symbol/search -> targeted range -> dependency` kullan; whole-repo okumayı varsayılan yapma.
6. Security/schema/payment/network/public-contract/persistence sınırlarında context'i kontrollü genişlet.
7. Runtime-compiled klasörlere AI context koyma; frontend context `docs/ai/scopes/frontend/` altında kalır.
8. Yeni commit sonrası eski CI kanıtı geçersizdir. `NO_CI != GREEN`.
9. Claude, Gemini veya başka AI reviewer onayı varsayılan merge kapısı değildir; yalnız kullanıcı o görevde açıkça isterse zorunlu hale gelir.
10. Merge için kullanıcı yetkisi ve latest exact PR head üzerinde gerekli Discourse CI kontrollerinin GREEN olması gerekir.
11. Testleri sırf CI yeşil olsun diye zayıflatma.
12. En düşük yeterli effort tier ile başla; risk/ambiguity nedeniyle yükselt ve riskli faz bitince de-escalate et.

Yeni görevde gereksiz context preload etmeden repository state'i fresh-read ederek başla.
