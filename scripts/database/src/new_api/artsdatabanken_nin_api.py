# %%
import requests
import json


class ArtsdatabankenNinApi:
    # base_url = 'https://nin-kode-api.artsdatabanken.no'
    headers = {
        'Accept': 'text/plain',
        # 'User-Agent': 'PostmanRuntime/7.29.0',
        # 'Accept': '*/*',
        # 'Accept-Encoding': 'gzip, deflate, br'
    }
    

    def __init__(self, base_url) -> None:
        self.base_url = base_url
        self.version = self.get_versions()[-1]
        self.all_codes = self.get_all_codes(self.version)

    def get_versions(self):
        url = f'{self.base_url}/versjoner'
        response = requests.get(url=url, headers=self.headers)
        return json.loads(response.content)

    def get_all_codes(self, version):
        url = f'{self.base_url}/{version}/koder/allekoder?tre=true'
        response = requests.get(url=url, headers=self.headers)
        return json.loads(response.content)

    def get_specific_code(self, code):
        resp = [x for x in self.all_codes if x['Kode']['Id'] == code]
        assert(len(resp) == 1)
        return resp[0]
    
    def get_specific_code_from_net(self, code):
        url = f'{self.base_url}/{self.version}/koder/hentkode/{code}'
        resp = requests.get(url=url, headers=self.headers)
        return json.loads(resp.content)

# %%
