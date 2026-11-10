export type SocialProvider = { platform: string; oauth_configured: boolean; setup_message: string | null };
export type SocialConnection = { id: string; platform: string; account_ref: string; display_name: string; creator_profile_id: string | null; connected: boolean; publishing_ready: boolean; updated_at: string | null };
const socialNames: Record<string, string> = { youtube: "YouTube Shorts", instagram: "Instagram", tiktok: "TikTok" };

type Props = {
  profileName: string;
  providers: SocialProvider[];
  connections: SocialConnection[];
  busy: string;
  pending: { platform: string; url: string } | null;
  error: string;
  onConnect: (platform: string) => void;
  onDisconnect: (connection: SocialConnection) => void;
  onRefresh: () => void;
  onOpenLogin: () => void;
  onCancelLogin: () => void;
};

export default function SocialConnections({ profileName, providers, connections, busy, pending, error, onConnect, onDisconnect, onRefresh, onOpenLogin, onCancelLogin }: Props) {
  return <section className="panel profile-panel social-connections" aria-label="Social account connections">
    <div className="heading"><div><h2>Destinations for {profileName}</h2><p className="note">Link the accounts this profile will publish to. You sign in directly with each network.</p></div>
      <button type="button" className="secondary" disabled={Boolean(busy)} onClick={onRefresh}>{busy === "refresh" ? "Checking…" : "Refresh accounts"}</button></div>
    {["youtube", "instagram", "tiktok"].map((platform) => {
      const provider = providers.find((item) => item.platform === platform);
      const accounts = connections.filter((item) => item.platform === platform);
      return <div className="social-provider" key={platform}>
        <div className="destination-card"><div><strong>{socialNames[platform]}</strong><p className="note">{accounts.length ? `${accounts.length} linked account${accounts.length === 1 ? "" : "s"}` : "No account linked"}</p></div>
          <button type="button" className="secondary" disabled={Boolean(busy) || !provider?.oauth_configured} onClick={() => onConnect(platform)}>
            {busy === platform ? "Opening login…" : accounts.length ? "Add account" : `Connect ${socialNames[platform]}`}</button></div>
        {!provider?.oauth_configured && <p className="note social-setup">{provider?.setup_message || "Checking connection setup…"}</p>}
        {accounts.map((account) => <div className="social-account" key={account.id}>
          <div><strong>{account.display_name}</strong><p className="note">{!account.connected ? "Authorization expired · reconnect" : account.publishing_ready ? "Connected · ready to publish" : "Connected · publishing setup pending"}</p></div>
          <div className="social-actions"><button type="button" className="secondary" disabled={Boolean(busy) || !provider?.oauth_configured} onClick={() => onConnect(platform)}>Reconnect</button>
            <button type="button" className="secondary" disabled={Boolean(busy)} onClick={() => onDisconnect(account)}>{busy === account.id ? "Disconnecting…" : "Disconnect from TV7"}</button></div>
        </div>)}
      </div>;
    })}
    {pending && <div className="social-login-status" role="status"><strong>Finish {socialNames[pending.platform]} authorization</strong><p className="note">Choose the account for {profileName} in the provider window. Return here when finished; Studio will check the connection.</p><div className="social-actions"><button type="button" className="secondary" onClick={onOpenLogin}>Open login again</button><button type="button" className="secondary" onClick={onCancelLogin}>Stop waiting</button></div></div>}
    {error && <p role="alert" className="error">{error}</p>}
  </section>;
}
